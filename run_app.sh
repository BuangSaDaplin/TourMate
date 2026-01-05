#!/bin/bash
echo "Starting TourMate App..."
echo ""
echo "Checking Flutter installation..."
flutter --version
echo ""
echo "Getting dependencies..."
flutter pub get
echo ""
echo "Running the app..."
flutter run