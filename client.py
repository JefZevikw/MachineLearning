#!/usr/bin/env python3

import socket
import sys
import getopt

HOST = '192.168.1.102'  # Standard loopback interface address (localhost)
PORT = 9090  # Port to listen on (non-privileged ports are > 1023)


def main(argv):
    inputfile = ''
    outputfile = ''
    try:
        opts, args = getopt.getopt(argv, "hi:o:", ["ifile=", "ofile="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile> -o <outputfile>')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <HOST> ')
            sys.exit()
        elif opt in ("-i"):
            HOST = arg
            print("host is ",HOST)



if __name__ == "__main__":
    main(sys.argv[1:])

    print ('Number of arguments:', len(sys.argv), 'arguments.')
    print ('Argument List:', str(sys.argv))
    msg = input('Message...: ')

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))

        while msg is not '':
            print('sending ' + msg + ' ...')
            total_msg = msg + ')\0'
            print(total_msg)

            s.sendall(total_msg.encode())
            dd = ''
            if total_msg.startswith('getfile('):
                fullpath = total_msg[7:len(total_msg) - 2]
                file_array = fullpath.split('/')
                print(file_array)
                print(len(file_array))
                filename = file_array[len(file_array)-1]
                print('filename to save is :' + filename)
                f = open(filename, 'wb')
                exit_socket = False
                while not dd.endswith('Hello from server') and not exit_socket:
                    data = s.recv(1024)
                    print(len(data))
                    if len(data) == 0:
                        exit_socket = True
                    else:
                        f.write(data)
                    dd = data.decode("utf-8")
                    print('Received', dd)
                    print('Received', len(dd))
                f.close()
            else:
                while not dd.endswith('Hello from server'):
                    data = s.recv(1024)
                    dd = data.decode("utf-8")
                    print('Received', dd)
                    print('Received', len(dd))
            msg = input('Message...: ')

    print('exit')



