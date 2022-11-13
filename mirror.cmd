@ECHO OFF
rclone sync b2:razxtest/4dos.info C:\Users\dave\GitHub\4dos.info\site --transfers 32 --progress -v --delete-excluded --ignore-case --exclude-from site-vs-files.txt
rclone sync b2:razxtest/4dos.info C:\Users\dave\GitHub\4dos.info\files --transfers 32 --progress -v --delete-excluded --ignore-case --include-from site-vs-files.txt

echo Files redirected from `site` to `files`
for /F %%x in (site-vs-files.txt) do echo %%x
