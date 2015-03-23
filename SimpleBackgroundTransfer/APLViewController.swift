//
//  APLViewController.swift
//  SimpleBackgroundTransfer
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/3/21.
//
//
//
/*
     File: APLViewController.h
     File: APLViewController.m
 Abstract: Main view controller; manages a URLSession.
  Version: 1.1

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2013 Apple Inc. All Rights Reserved.

 */

import UIKit

@objc(APLViewController)
class ViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate {
    
    
    
    
    //#warning To run this sample correctly, you must set an appropriate URL here.
    private let DownloadURLString = "http://localhost/bigImage.png"
    
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var progressView: UIProgressView!
    
    var session: NSURLSession!
    var downloadTask: NSURLSessionDownloadTask?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.session = self.backgroundSession
        
        self.progressView.progress = 0
        self.imageView.hidden = false
        self.progressView.hidden = true
    }
    
    
    @IBAction func start(AnyObject) {
        if self.downloadTask != nil {
            return
        }
        
        /*
        Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.
        */
        let downloadURL = NSURL(string: DownloadURLString)!
        let request = NSURLRequest(URL: downloadURL)
        self.downloadTask = self.session.downloadTaskWithRequest(request)
        self.downloadTask!.resume()
        
        self.imageView.hidden = true
        self.progressView.hidden = false
    }
    
    
    /*
    Using disptach_once here ensures that multiple background sessions with the same identifier are not created in this instance of the application. If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
    */
    //### Using static var to get the disptach_once-similar effect.
    //### Removed (instance's) lazy var to avoid cyclic reference.
    var backgroundSession: NSURLSession {
        struct My {
            static var staticSelf: ViewController!
            static var backgroundSessionInstance: NSURLSession = {
                let configuration = NSURLSessionConfiguration.backgroundSessionConfiguration("com.example.apple-samplecode.SimpleBackgroundTransfer.BackgroundSession")
                return NSURLSession(configuration: configuration, delegate: staticSelf, delegateQueue: nil)
                }()
        }
        My.staticSelf = self
        return My.backgroundSessionInstance
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        BLog()
        
        /*
        Report progress on the task.
        If you created more than one task, you might keep references to them and report on them individually.
        */
        
        if downloadTask === self.downloadTask {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            BLog(format: "DownloadTask: %@ progress: %lf", downloadTask, progress)
            dispatch_async(dispatch_get_main_queue()) {
                self.progressView.progress = Float(progress)
            }
        }
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL downloadURL: NSURL) {
        BLog()
        
        /*
        The download completed, you need to copy the file at targetPath before the end of this block.
        As an example, copy the file to the Documents directory of your app.
        */
        let fileManager = NSFileManager.defaultManager()
        
        let URLs = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask) as! [NSURL]
        let documentsDirectory = URLs[0]
        
        let originalURL = downloadTask.originalRequest.URL!
        let destinationURL = documentsDirectory.URLByAppendingPathComponent(originalURL.lastPathComponent!)
        var errorCopy: NSError? = nil
        
        // For the purposes of testing, remove any esisting file at the destination.
        fileManager.removeItemAtURL(destinationURL, error: nil)
        let success = fileManager.copyItemAtURL(downloadURL, toURL: destinationURL, error: &errorCopy)
        
        if success {
            dispatch_async(dispatch_get_main_queue()) {
                let image = UIImage(contentsOfFile: destinationURL.path!)
                self.imageView.image = image
                self.imageView.hidden = false
                self.progressView.hidden = true
            }
        } else {
            /*
            In the general case, what you might do in the event of failure depends on the error and the specifics of your application.
            */
            BLog(format: "Error during the copy: %@", errorCopy!.localizedDescription)
        }
    }
    
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        BLog()
        
        if error == nil {
            NSLog("Task: %@ completed successfully", task)
        } else {
            NSLog("Task: %@ completed with error: %@", task, error!.localizedDescription)
        }
        
        let progress = Double(task.countOfBytesReceived) / Double(task.countOfBytesExpectedToReceive)
        dispatch_async(dispatch_get_main_queue()) {
            self.progressView.progress = Float(progress)
        }
        
        self.downloadTask = nil
    }
    
    
    /*
    If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
    */
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
            appDelegate.backgroundSessionCompletionHandler = nil
            completionHandler()
        }
        
        NSLog("All tasks are finished")
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        BLog()
    }
    
}