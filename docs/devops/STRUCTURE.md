# Project Structure

This monorepo follows a well-organized structure to manage multiple components:

## Directory Layout

```
apparule/
├── .dockerignore          # Docker build exclusions
├── .editorconfig          # Editor configuration
├── .gitignore             # Git exclusions
├── CHANGELOG.md           # Version history
├── CODEOWNERS             # Code ownership rules
├── CONTRIBUTING.md        # Contribution guidelines
├── LICENSE                # Project license
├── Makefile               # Build automation
├── README.md              # Project overview
├── STRUCTURE.md           # This file
│
├── api/                   # Backend APIs
│   └── common/            # Shared API utilities and common code
│
├── deploy/                # Deployment configurations
│   ├── docker/            # Docker build configurations
│   ├── helm/              # Kubernetes Helm charts
│   └── terraform/         # Infrastructure as Code
│
├── docs/                  # Documentation
│   ├── api/               # API documentation
│   └── ui/                # UI/UX documentation
│
├── mobile/                # Mobile applications
│   ├── flutter/           # Flutter cross-platform app
│   │   ├── lib/           # Dart source code
│   │   ├── test/          # Unit tests
│   │   ├── assets/        # Images and resources
│   │   └── pubspec.yaml   # Flutter dependencies
│   ├── android/           # Android native code
│   └── ios/               # iOS native code
│
├── scripts/               # Build and automation scripts
│   └── refactor-structure.sh  # Structure refactoring script
│
└── web/                   # Web applications
    └── home/
        └── app/           # Main web application
```

## Component Guide

### Mobile (`/mobile`)
- **flutter/**: Cross-platform Flutter application with shared UI and business logic
- **android/**: Android-specific native configurations and modules
- **ios/**: iOS-specific native configurations and modules

### Web (`/web`)
- **home/app/**: Main web application (home page and core functionality)

### Backend (`/api`)
- **common/**: Shared utilities, base classes, and common functionality for all APIs

### Deployment (`/deploy`)
- **docker/**: Containerization configurations for services
- **helm/**: Kubernetes deployment charts
- **terraform/**: Infrastructure provisioning and management

### Documentation (`/docs`)
- **api/**: API reference and backend documentation
- **ui/**: UI component library and design documentation

## Development Workflow

### Flutter Development
```bash
cd mobile/flutter
flutter pub get
flutter run
```

### Web Development
```bash
cd web/home/app
npm install
npm start
```

## Build Automation

Use the Makefile for common tasks:
```bash
make help      # Show all available tasks
make setup     # Initialize environment
make get       # Fetch dependencies
make clean     # Clean build artifacts
make test      # Run tests
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.
