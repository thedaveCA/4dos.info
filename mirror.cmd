@ECHO OFF
rclone sync b2:razxtest/4dos.info C:\Users\dave\GitHub\4dos.info\site --transfers 32 --progress -v --delete-excluded --ignore-case --no-update-modtime --modify-window 1s --fast-list --exclude-from site-vs-files.txt --dry-run
rclone sync b2:razxtest/4dos.info C:\Users\dave\GitHub\4dos.info\files --transfers 32 --progress -v --delete-excluded --ignore-case --no-update-modtime --modify-window 1s --fast-list --include-from site-vs-files.txt
rclone sync b2:razxtest/4dos.info r2:sites/files.4dos.info/ --transfers 32 --progress -v --delete-excluded --ignore-case --no-update-modtime --modify-window 1s --fast-list --include-from site-vs-files.txt

echo (http.host eq "4dos.info" and (> transform-rule.txt
echo ends_with(http.request.uri.path, ".binary")>> transform-rule.txt
for /f "delims=*"  %%x in (site-vs-files.txt) do echo or ends_with(http.request.uri.path, "%%x")>> transform-rule.txt
echo ))>> transform-rule.txt
