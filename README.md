# S3 backup


The script is able to set up continuous upload of new changes to AWS S3.

```>s3-backup.sh --help      
Usage: s3-backup/s3-backup.sh bucket_name [local_folder]
```

Upload is paused until `inotify` event will occur in the specified directory.

If the bucket is not yet exists. The script will allow you to create it. Versioning is automatically enabled, there is an option to specify the number of days before objects will be transferred to Glacier.