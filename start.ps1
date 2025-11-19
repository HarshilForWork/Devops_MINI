
# Quick Start Script for Local Development
# Run this to set up and start the Book Manager application

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Book Manager - Local Development Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting services with Docker Compose..." -ForegroundColor Yellow
docker-compose up -d

Write-Host ""
Write-Host "Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Checking container status..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  ✅ Application Started Successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application at:" -ForegroundColor Cyan
Write-Host "  🌐 Frontend:    http://localhost:5000" -ForegroundColor White
Write-Host "  🔌 Backend API: http://localhost:5001" -ForegroundColor White
Write-Host "  🗄️  Database:   localhost:3306" -ForegroundColor White
Write-Host ""
Write-Host "Test credentials:" -ForegroundColor Cyan
Write-Host "  Email:    test@example.com" -ForegroundColor White
Write-Host "  Password: test123" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  View logs:      docker-compose logs -f" -ForegroundColor White
Write-Host "  Stop services:  docker-compose down" -ForegroundColor White
Write-Host "  Restart:        docker-compose restart" -ForegroundColor White
Write-Host ""
Write-Host "Opening browser..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Start-Process "http://localhost:5000"
