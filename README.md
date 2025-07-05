# Money Saver App

A personal finance management application built with Flutter that helps you track expenses, manage budgets, and get AI-powered financial insights.

## Quick Setup

# IMPORTANT TO NOTE, PLEASE USE THE CSV PROVIDED AT THE ROOT OF THIS PROJECT. IT USES AN ID COLUMN WHICH IS NECESSARY FOR THE CSV FUNCTIONALITY IN FLUTTER

### Prerequisites
- [Docker](https://www.docker.com/get-started)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)

### Running the Application

1. **Start Ollama container**:
   ```bash
   docker pull ollama/ollama
   docker run -d -p 11434:11434 --name ollama ollama/ollama
   ```

2. **Download the AI model**:
   ```bash
   docker exec -it ollama ollama pull phi3:mini
   ```

3. **Run the Flutter app**:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

4. **Access the application**:
   - **Flutter App**: URL provided when running

### Stopping the Application
```bash
docker stop ollama
docker rm ollama
```

## Features
- 📊 Upload and analyze CSV bank statements
- 💰 Set and track monthly budgets
- 📈 Visual spending analytics with charts
- 🎯 Create savings goals
- 🤖 AI chatbot for financial advice (powered by Ollama)
- 🌙 Dark/Light theme support

## Usage
1. Click "Load CSV File" to upload your bank statement
2. Set a monthly budget to track your spending
3. Use the chat button (💬) to ask the AI assistant about your finances
4. Explore the analytics dashboard for insights into your spending patterns
