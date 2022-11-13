@ECHO OFF
rclone sync b2:razxtest/4dos.info C:\Users\dave\GitHub\4dos.info\site --transfers 32 --progress -v --delete-excluded --ignore-case --no-update-modtime --modify-window 1s --exclude-from site-vs-files.txt
rclone sync b2:razxtest/4dos.info C:\Users\dave\GitHub\4dos.info\files --transfers 32 --progress -v --delete-excluded --ignore-case --no-update-modtime --modify-window 1s --include-from site-vs-files.txt
::rclone sync b2:razxtest/4dos.info r2:sites/files.4dos.info/ --transfers 32 --progress -v --delete-excluded --ignore-case --no-update-modtime --modify-window 1s --include-from site-vs-files.txt

echo Files redirected from `site` to `files`
for /F %%x in (site-vs-files.txt) do echo %%x
