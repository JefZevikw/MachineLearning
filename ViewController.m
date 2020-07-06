//
//  ViewController.m
//  files
//
//  Created by bebik on 04/07/2020.
//  Copyright © 2020 bebik. All rights reserved.
//

#include <unistd.h>
#include <stdio.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <string.h>
#import "ViewController.h"

@interface ViewController ()
- (void) buttona;
-(void)methodWithOneParameter:(id)parameter;
@end
@implementation ViewController

#define PORT 9090

static int listen_loop(char *buffer, char *hello, int new_socket) {
    printf("read %s\n",buffer );
    if (strncmp(buffer,"getfile",7) ==0)
    {
        char filebuf[600]={0};
        printf("getfile %s\n",buffer);
        size_t size =strlen(buffer);
        strncpy(filebuf,buffer+8,size-9);
        printf(" path is '%s' ",filebuf);
        int fd = open(filebuf,O_RDONLY);
        if (fd >0)
        {
            int sz_r=read(fd,filebuf,600);
            while ( sz_r > 0)
            {
            
                size_t sz = send(new_socket , filebuf , sz_r , 0);
                NSLog(@"send %d",sz);
                sz_r=read(fd,filebuf,600);
            }
            close(fd);
            return -1;
        }
        else{
            NSLog(@"Error open file ");
        }
        
       
    }
    if (strncmp(buffer,"getfldr",7)==0)
    {
        
        char filebuf[600]={0};
        printf("getfldr %s\n",buffer);
        size_t size =strlen(buffer);
        strncpy(filebuf,buffer+8,size-9);
        printf("path is '%s' ",filebuf);
        NSString * folder_path = [NSString stringWithUTF8String:filebuf];
        if ( strcmp(filebuf,"$") ==0 )
        {
            folder_path = NSHomeDirectory();
            folder_path = [NSString stringWithFormat:@"%@/",folder_path];
        }
        else if ( strcmp(filebuf,"#") ==0 )
        {
            NSLog(@"Documents Directory: %@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);

            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *resultURL = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSAllDomainsMask appropriateForURL:nil create:NO error:nil];
            NSDirectoryEnumerator<NSURL *> * dirContents = [fileManager enumeratorAtURL:resultURL includingPropertiesForKeys:nil options:nil errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                printf("inside\n");
                return true;
            }];
            for (NSURL *tString in dirContents) {
               
                NSLog(tString.absoluteString);
            }
           // folder_path = NSHomeDirectory();
        }
        checkattributes(folder_path,  new_socket);
    }
    send(new_socket , hello , strlen(hello) , 0 );
    printf("Hello message sent\n");
    return 0;
}

void opensocket ()
{
    int server_fd, new_socket, valread;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);
    char buffer[1024] = {0};
    char *hello = "Hello from server";
       
    // Creating socket file descriptor
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0)
    {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }
       
    // Forcefully attaching socket to the port 8080
    if (setsockopt(server_fd, SOL_SOCKET,  SO_REUSEPORT,
                                                  &opt, sizeof(opt)))
    {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR ,
                                                  &opt, sizeof(opt)))
    {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons( PORT );
       
    // Forcefully attaching socket to the port 8080
    if (bind(server_fd, (struct sockaddr *)&address,
                                 sizeof(address))<0)
    {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }
    printf("bind");
    if (listen(server_fd, 3) < 0)
    {
        perror("listen");
        exit(EXIT_FAILURE);
    }
    printf("listen");
    if ((new_socket = accept(server_fd, (struct sockaddr *)&address,
                       (socklen_t*)&addrlen))<0)
    {
        perror("accept");
        exit(EXIT_FAILURE);
    }
    printf("accept\n");
    
    while (valread = read( new_socket , buffer, 1024) ){
        int res = listen_loop(buffer, hello, new_socket);
        if (res == -1 ){
            shutdown(new_socket,2);
            close(new_socket);
            printf("socket closed");
            
            if ((new_socket = accept(server_fd, (struct sockaddr *)&address,
                                  (socklen_t*)&addrlen))<0)
               {
                   perror("accept");
                   exit(EXIT_FAILURE);
               }
            
            }
    }
    
}
void checkattributes(NSString * path, int new_socket)
{
    NSFileManager *filemgr;
    NSString *currentpath;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
       
      
    filemgr = [[NSFileManager alloc] init];
    printf("\nchecking directory %s\n",path.UTF8String);
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil ];
     
     NSError *attributeserror = nil;

    if (fileAttributes != nil)
    {
         
        NSNumber *fileSize;
        NSString *fileOwner;
        NSDate *fileModDate;
        NSFileAttributeKey  ftype;
         
         NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:path error:&attributeserror];
         for (NSString *tString in dirContents)
         {
             NSLog(@"%@\n",tString);
             NSString *complete = [NSString stringWithFormat:@"%@/%@", path,tString];

             NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:complete error:&attributeserror ];
        
             if (fileAttributes != nil)
             {
                 
                  
                 if ((ftype = [fileAttributes objectForKey:NSFileType]))
                 {
                          
                     if (ftype == NSFileTypeDirectory){
                              printf ("sending directory %s\n",tString.UTF8String);
                              send(new_socket, "#," , 2 ,0 );
                              send(new_socket, ftype.UTF8String , strlen(ftype.UTF8String) ,0 );
                              send(new_socket, "," , 1 ,0 );
                              send(new_socket, complete.UTF8String , strlen(complete.UTF8String) ,0 );
                              send(new_socket, "," , 1 ,0 );
                              
                         
                              //we can do it recursivly here ..
                              //checkattributes(complete);
                      
                     }
                  
                     else
                  
                     {
                      
                      
                         send(new_socket, "#," , 2 ,0 );
                         
                         send(new_socket, ftype.UTF8String , strlen(ftype.UTF8String) ,0 );
                      
                         send(new_socket, "," , 1 ,0 );
                      
                         send(new_socket, complete.UTF8String , strlen(complete.UTF8String) ,0 );
                      
                         send(new_socket, "," , 1 ,0 );
                      
                         printf ("file %s\n",tString.UTF8String);
                  
                     }
                      
                      
                     if ((fileSize = [fileAttributes objectForKey:NSFileSize])) {
                         char bufsize[50]={0};

                         sprintf(bufsize, "%lld",[fileSize unsignedLongLongValue] );
                         send(new_socket, bufsize , strlen(bufsize) ,0 );
                         send(new_socket, "," , 1 ,0 );
                         NSLog(@"File size: %qi\n", [fileSize unsignedLongLongValue]);
                       
                     }
                     
                      
                     if ((fileOwner = [fileAttributes objectForKey:NSFileOwnerAccountName])) {
                           
                         send(new_socket, fileOwner.UTF8String , strlen(fileOwner.UTF8String) ,0 );
                         send(new_socket, "," , 1 ,0 );
                         NSLog(@"Owner: %@\n", fileOwner);

                     }
                     if ((fileModDate = [fileAttributes objectForKey:NSFileModificationDate])) {
                         
                         NSString *dateString = [NSDateFormatter localizedStringFromDate:fileModDate
                                                                               dateStyle:NSDateFormatterShortStyle
                                                                               timeStyle:NSDateFormatterFullStyle];
                         NSLog(@"%@",dateString);
                        send(new_socket, dateString.UTF8String , strlen(dateString.UTF8String) ,0 );
                        send(new_socket, "," , 1 ,0 );
                        
                         //  NSLog(@"Modification date: %@\n", fileModDate);
                       }
                       
                     if (ftype = [fileAttributes objectForKey:NSFileType]) {
                           NSLog(@"type : %@\n", ftype);
                     }
                      
              
                 }
                
         
             }
             else{
                 send(new_socket, "#," , 2 ,0 );
                    
              
                 
                    send(new_socket, complete.UTF8String , strlen(complete.UTF8String) ,0 );
                 
                    send(new_socket, "," , 1 ,0 );
                    send(new_socket, "ERROR" , strlen("ERROR") ,0 );
                    send(new_socket, "," , 1 ,0 );
                    send(new_socket, attributeserror.localizedDescription.UTF8String, strlen(attributeserror.localizedDescription.UTF8String) ,0 );
                 NSLog(@"error = %@",attributeserror.localizedDescription);
             }
         }
    }
        
    else
        
    {
         send(new_socket, "path is invalid" , strlen("path is invalid") ,0 );
         
         NSLog(@"Path (%@) is invalid.", path);
     
        
    }
    
}


-(void)createfile{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:docsDir];
    [[NSFileManager defaultManager] createFileAtPath:@"temp2.dat" contents:nil attributes:nil];
    NSString * filename = [NSString stringWithFormat:@"%@/temp2.dat",docsDir];
    FILE *f = fopen(filename.UTF8String,"w");
    char buffer[] = "aslkjdfhalksjdhflaksjhflkajsdhlfajsdhflkajshdlfkjashdf";
    fprintf(f, "%s", buffer);
    fclose(f);
    
}
- (void)buttona {
 
//  [self createfile];
    NSFileManager *filemgr;
    NSString *currentpath;
    filemgr = [[NSFileManager alloc] init];
    currentpath = [filemgr currentDirectoryPath];
    printf(" directory %s\n ", currentpath.UTF8String);
    NSString *p2 = [[NSProcessInfo processInfo] environment][@"PWD"];
    printf("home directory %s\n ", NSHomeDirectory().UTF8String);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *path = NSHomeDirectory();
     
     
         opensocket();
         
     
    //checkattributes(currentpath);
    
    
   // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
   // NSString *docsDir = [paths objectAtIndex:0];
   // [[NSFileManager defaultManager] changeCurrentDirectoryPath:docsDir];
   // [[NSFileManager defaultManager] createFileAtPath:@"temp2.dat" contents:nil attributes:nil];

}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    CGFloat testHeight = 50;
     CGFloat testWidth = 100;
     CGFloat spaceing = 10;
     int number = 2;

     for (int i = 0; i < number; i++) {
         UIButton *button =  [[UIButton alloc]initWithFrame:CGRectMake(spaceing + testWidth * i + spaceing * i , 100 , testWidth, testHeight )];
         [button addTarget:self action:@selector(buttona) forControlEvents:UIControlEventTouchUpInside];
         [button setBackgroundColor:[UIColor redColor]];
         [self.view addSubview:button];
     }
}


@end

