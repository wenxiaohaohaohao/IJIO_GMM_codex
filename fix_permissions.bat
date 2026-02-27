@echo off
REM ============================================================================
REM fix_permissions.bat
REM 鐩殑锛氱Щ闄よ緭鍑虹洰褰曚腑鐨勫彧璇诲睘鎬?
REM ============================================================================

echo ============================================
echo 鏉冮檺淇鑴氭湰
echo ============================================

cd /d "D:\paper\IJIO_GMM_codex_en\methods\non_hicks"

echo.
echo 銆愬鐞嗐€憆esults/data
attrib -r "results\data" /s /d
attrib -r "results\data\*.dta" /s

echo.
echo 銆愬鐞嗐€憆esults/logs
attrib -r "results\logs" /s /d
attrib -r "results\logs\*.log" /s

echo.
echo 銆愬鐞嗐€慸ata/work
attrib -r "data\work" /s /d
attrib -r "data\work\*.dta" /s

echo.
echo ============================================
echo 鏉冮檺淇瀹屾垚
echo ============================================

REM 楠岃瘉淇
echo.
echo 銆愰獙璇併€戞祴璇曞啓鍏ユ潈闄?..
cd "results\data"
(
    echo Permission test
) > test_permission.txt

if exist test_permission.txt (
    echo 鎴愬姛锛氬彲浠ュ啓鍏ユ枃浠?
    del test_permission.txt
) else (
    echo 澶辫触锛氭棤娉曞啓鍏ユ枃浠?
)

pause

