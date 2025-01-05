#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "opencv-python>=4.8.0",
#     "pillow>=10.0.0",
# ]
# ///

# Platform support:
# - Linux: Uses xprintidle for idle detection and notify-send for notifications
# - macOS: Uses ioreg for idle detection and osascript for notifications
#
import logging
import subprocess
import time
from datetime import datetime
from pathlib import Path

import cv2
import numpy as np

# Setup logging with timestamp and level
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


class RoomLightMonitor:
    def __init__(self, verbose=False):
        self.image_dir = Path("room_images")
        self.image_dir.mkdir(exist_ok=True)
        self.verbose = verbose
        self.cap = None

        # Light level thresholds (min, max) for different times of day
        self.light_thresholds = {
            "morning": (50, 200),  # 6-11:  min 50, max 200
            "day": (100, 250),  # 11-16: min 100, max 250
            "evening": (30, 150),  # 16-21: min 30, max 150
            "night": (20, 80),  # 21-6:  min 20, max 80 (stricter at night)
        }

    def get_time_period(self):
        """Determine current time period for light threshold"""
        hour = datetime.now().hour
        if 6 <= hour < 11:
            return "morning"
        elif 11 <= hour < 16:
            return "day"
        elif 16 <= hour < 21:
            return "evening"
        else:
            return "night"

    def get_idle_time(self):
        """Get system idle time in milliseconds"""
        import platform

        system = platform.system()
        try:
            if system == "Darwin":  # macOS
                # Get HIDIdleTime using ioreg
                result = subprocess.run(
                    ["ioreg", "-c", "IOHIDSystem"],
                    capture_output=True,
                    text=True,
                    check=True,
                )
                for line in result.stdout.splitlines():
                    if "HIDIdleTime" in line:
                        # Extract the idle time value (in nanoseconds)
                        ns = int(line.split("=")[-1].strip())
                        # Convert nanoseconds to milliseconds
                        return ns // 1_000_000
                logger.error("Could not find HIDIdleTime in ioreg output")
                return 0
            else:  # Linux
                result = subprocess.run(
                    ["xprintidle"], capture_output=True, text=True, check=True
                )
                return int(result.stdout.strip())
        except subprocess.CalledProcessError as e:
            logger.error(f"Error getting idle time: {e}")
            return 0
        except ValueError as e:
            logger.error(f"Error parsing idle time: {e}")
            return 0

    def is_user_active(self):
        """Check if user has been active in the last 5 minutes"""
        idle_time = self.get_idle_time()
        # Convert 5 minutes to milliseconds
        return idle_time < 5 * 60 * 1000

    def init_camera(self):
        """Initialize the camera if not already initialized"""
        if self.cap is None:
            self.cap = cv2.VideoCapture(0)
            if not self.cap.isOpened():
                raise RuntimeError("Could not open webcam")
            logger.debug("Camera initialized")

    def release_camera(self):
        """Release the camera if initialized"""
        if self.cap is not None:
            self.cap.release()
            self.cap = None
            logger.debug("Camera released")

    def capture_and_analyze(self):
        """Capture image and analyze light levels"""
        try:
            self.init_camera()
            ret, frame = self.cap.read()
            if not ret:
                logger.error("Failed to capture image")
                return
        finally:
            self.release_camera()

        # Save image
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        image_path = self.image_dir / f"room_{timestamp}.jpg"
        cv2.imwrite(str(image_path), frame)

        # Convert to grayscale and calculate average brightness
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        avg_brightness = np.mean(gray)

        # Get thresholds for current time
        time_period = self.get_time_period()
        min_threshold, max_threshold = self.light_thresholds[time_period]

        # Check if room is too dark or too bright
        if avg_brightness < min_threshold:
            self.send_notification(
                f"Room is too dark (brightness: {avg_brightness:.1f})",
                f"Recommended range for {time_period}: {min_threshold}-{max_threshold}",
            )
            logger.info(f"Room too dark: {avg_brightness:.1f} < {min_threshold}")
        elif avg_brightness > max_threshold:
            self.send_notification(
                f"Room is too bright (brightness: {avg_brightness:.1f})",
                f"Recommended range for {time_period}: {min_threshold}-{max_threshold}",
            )
            logger.info(f"Room too bright: {avg_brightness:.1f} > {max_threshold}")
        else:
            logger.info(
                f"Light levels okay: {avg_brightness:.1f} (range: {min_threshold}-{max_threshold})"
            )

        return avg_brightness

    def send_notification(self, summary, body):
        """Send desktop notification"""
        import platform

        system = platform.system()
        try:
            if system == "Darwin":  # macOS
                # Escape quotes in the message
                summary = summary.replace('"', '\\"')
                body = body.replace('"', '\\"')
                # Use osascript to send notification
                script = f'''display notification "{body}" with title "{summary}"'''
                subprocess.run(["osascript", "-e", script])
            else:  # Linux
                subprocess.run(
                    [
                        "notify-send",
                        "--urgency=normal",
                        "--icon=weather-clear",
                        summary,
                        body,
                    ]
                )
        except Exception as e:
            logger.error(f"Failed to send notification: {e}")

    def cleanup(self):
        """Release webcam if needed"""
        self.release_camera()

    def run(self):
        """Main monitoring loop"""
        logger.info("Starting room light monitoring")
        logger.info(f"Images will be saved to: {self.image_dir}")
        # Log thresholds in a more readable format
        logger.info("Light thresholds (min-max):")
        for period, (min_val, max_val) in self.light_thresholds.items():
            logger.info(f"  {period:8}: {min_val:3}-{max_val:3}")
        logger.info(f"Verbose mode: {self.verbose}")

        # Set check interval based on verbose mode
        check_interval = 30 if self.verbose else 300
        interval_desc = "30 seconds" if self.verbose else "5 minutes"

        try:
            while True:
                time_period = self.get_time_period()
                if self.verbose:
                    logger.info(f"Current time period: {time_period}")

                if self.is_user_active():
                    if self.verbose:
                        logger.info("User is active, capturing image...")
                    self.capture_and_analyze()
                else:
                    if self.verbose:
                        logger.info("User inactive, skipping capture")

                if self.verbose:
                    logger.info(f"Waiting {interval_desc} before next check...")
                time.sleep(check_interval)
        except KeyboardInterrupt:
            logger.info("Monitoring stopped by user")
        finally:
            self.cleanup()
            logger.info("Cleanup complete")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Monitor room light levels")
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output"
    )
    args = parser.parse_args()

    try:
        logger.info("Initializing RoomLightMonitor...")
        monitor = RoomLightMonitor(verbose=args.verbose)
        monitor.run()
    except Exception as e:
        logger.error(f"Failed to start: {e}", exc_info=True)
        exit(1)
