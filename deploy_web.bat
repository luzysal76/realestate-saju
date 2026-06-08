@echo off
echo ============================================
echo  부동산 사주 - Firebase Hosting 배포
echo ============================================
echo.
cd /d "D:\Real Estate Luck in Saju"

echo [1단계] Firebase 로그인
echo - 브라우저가 열리면 Google 계정으로 로그인하세요
echo - 로그인 완료 후 이 창으로 돌아오세요
echo.
call npx firebase-tools login
if %errorlevel% neq 0 (
    echo 로그인 실패. 다시 시도해주세요.
    pause
    exit /b 1
)

echo.
echo [2단계] Firebase Hosting 배포 중...
call npx firebase-tools deploy --only hosting --project changemindsupport-center
if %errorlevel% neq 0 (
    echo 배포 실패.
    pause
    exit /b 1
)

echo.
echo ============================================
echo  배포 완료!
echo  URL: https://changemindsupport-center.web.app
echo ============================================
pause
