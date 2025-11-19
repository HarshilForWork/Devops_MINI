# Stop all Docker services
# Run this to cleanly shut down the application

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Stopping Book Manager Services" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Stopping Docker containers..." -ForegroundColor Yellow
docker-compose down

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  ✅ All services stopped" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To start again, run: .\start.ps1" -ForegroundColor Cyan
