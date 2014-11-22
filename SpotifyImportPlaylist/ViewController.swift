//
//  ViewController.swift
//  SpotifyImportPlaylist
//
//  Created by Felix Lapalme on 2014-11-22.
//  Copyright (c) 2014 Felix Lapalme. All rights reserved.
//

import Cocoa
import AppKit

var trackURIs = ""
var notFoundURIs = ""
var totalTracks = 0;
var matchedTracks = 0;
var notFoundTracks = 0;
let marketCodes = ["AD","AE","AF","AG","AI","AL","AM","AN","AO","AQ","AR","AS","AT","AU","AW","AX","AZ","BA","BB","BD","BE","BF","BG","BH","BI","BJ","BM","BN","BO","BR","BS","BT","BV","BW","BY","BZ","CA","CC","CD","CF","CG","CH","CI","CK","CL","CM","CN","CO","CR","CU","CV","CX","CY","CZ","DE","DJ","DK","DM","DO","DZ","EC","EE","EG","EH","ER","ES","ET","FI","FJ","FK","FM","FO","FR","GA","GB","GD","GE","GF","GG","GH","GI","GL","GM","GN","GP","GQ","GR","GS","GT","GU","GW","GY","HK","HM","HN","HR","HT","HU","ID","IE","IL","IN","IO","IQ","IR","IS","IT","JM","JO","JP","KE","KG","KH","KI","KM","KN","KP","KR","KW","KY","KZ","LA","LB","LC","LI","LK","LR","LS","LT","LU","LV","LY","MA","MC","MD","ME","MG","MH","MK","ML","MM","MN","MO","MP","MQ","MR","MS","MT","MU","MV","MW","MX","MY","MZ","NA","NC","NE","NF","NG","NI","NL","NO","NP","NR","NU","NZ","OM","PA","PE","PF","PG","PH","PK","PL","PM","PN","PR","PS","PT","PW","PY","QA","RE","RO","RS","RU","RW","SA","SB","SC","SD","SE","SG","SH","SI","SJ","SK","SL","SM","SN","SO","SR","ST","SV","SY","SZ","TC","TD","TF","TG","TH","TJ","TK","TL","TM","TN","TO","TR","TT","TV","TW","TZ","UA","UG","UM","US","UY","UZ","VA","VC","VE","VG","VI","VN","VU","WF","WS","YE","YT","ZA","ZM","ZW"]

class Request : NSObject {
    func send(url: String, f: (String)-> ()) {
        var request = NSURLRequest(URL: NSURL(string: url)!)
        var response: NSURLResponse?
        var error: NSErrorPointer = nil
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: error)
        var reply = NSString(data: data!, encoding: NSUTF8StringEncoding)
        f(reply!)
    }
}

class ViewController: NSViewController, NSOpenSavePanelDelegate {
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var countryComboBox: NSComboBoxCell!
    @IBAction func chooseXML(sender: NSButton) {
        
        var openPanel:NSOpenPanel = NSOpenPanel();
        openPanel.canChooseFiles = true;
        openPanel.canChooseDirectories = false;
        openPanel.allowsMultipleSelection = false;
        openPanel.allowedFileTypes = ["xml"]
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if (result == NSFileHandlingPanelOKButton) {
                dispatch_async(dispatch_get_main_queue()) {
                    
                    openPanel.close()
                    
                    sender.enabled = false;
                }
                
                
                for url in openPanel.URLs {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                        var playlist = NSDictionary(contentsOfURL: url as NSURL)
                        let songIDs = (((playlist?.objectForKey("Playlists")) as NSArray).objectAtIndex(0) as NSDictionary).objectForKey("Playlist Items") as NSArray
                        let songMetadata = (((playlist?.objectForKey("Tracks")) as NSDictionary))
                        totalTracks = songMetadata.allValues.count
                        
                        //search for the song URIs and stores them in notFoundURIs
                        for song in songMetadata.allValues{
                            self.searchForTrackID(song.objectForKey("Name") as String,artistName: song.objectForKey("Artist") as String)
                        }
                        
                        NSPasteboard.generalPasteboard().clearContents()
                        NSPasteboard.generalPasteboard().writeObjects([trackURIs])
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            sender.enabled = true;
                            
                            let myPopup:NSAlert = NSAlert()
                            myPopup.addButtonWithTitle("OK")
                            
                            myPopup.messageText = "\(notFoundTracks) tracks not found:";
                            
                            var textView = NSTextView(frame: NSMakeRect(0, 0, 300, 300))
                            var scrollView = NSScrollView(frame: NSMakeRect(0,0,300,300))
                            
                            var contentSize = scrollView.contentSize
                            scrollView.borderType = NSBorderType(rawValue: 0)!
                            scrollView.hasVerticalScroller = true
                            scrollView.hasHorizontalScroller = true
                            
                            var theTextView = NSTextView(frame: NSMakeRect(0, 0,
                                contentSize.width, contentSize.height))
                            theTextView.editable = false
                            theTextView.minSize = NSMakeSize(0.0, contentSize.height);
                            theTextView.maxSize = NSMakeSize(CGFloat(FLT_MAX), CGFloat(FLT_MAX));
                            theTextView.verticallyResizable = true;
                            theTextView.horizontallyResizable = false;
                            
                            theTextView.textContainer?.containerSize = NSMakeSize(contentSize.width, CGFloat(FLT_MAX))
                            theTextView.textContainer?.widthTracksTextView = true;
                            theTextView.string = notFoundURIs
                            scrollView.documentView = theTextView
                            
                            myPopup.accessoryView = scrollView
                            
                            if myPopup.runModal() == NSAlertFirstButtonReturn {
                                //here we reset everything
                                totalTracks = 0;
                                matchedTracks = 0;
                                notFoundTracks = 0;
                                
                            }
                            
                            self.statusLabel.stringValue = "Spotify Track URIs copied to clipboard!"
                            self.progressIndicator.doubleValue = 0.0;
                        }
                    }
                }
            }
        }
    }
    
    func openPanelDidClose(){
        println("hi i did close")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        countryComboBox.addItemsWithObjectValues(marketCodes)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func searchForTrackID(trackName: NSString, artistName: NSString){
        var hasArtist = (artistName != "")
        var request = Request()
        var requestString = "https://api.spotify.com/v1/search?q="
        requestString += trackName.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        if(hasArtist){
            requestString += "+artist:"
            requestString += artistName.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        }
        var countryCode = marketCodes[countryComboBox.indexOfSelectedItem]
        println(countryCode)
        requestString += "&type=track&market=\(marketCodes[countryComboBox.indexOfSelectedItem])&limit=1"
        
        request.send(requestString, {(result: String)-> () in
            var resultData = result.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            var jsonResult: NSDictionary! = NSJSONSerialization.JSONObjectWithData(resultData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
            
            var resultsArray = (jsonResult.objectForKey("tracks") as NSDictionary).objectForKey("items") as NSArray;
            if(resultsArray.count > 0){
                var trackURI = "spotify:track:"+(((resultsArray).objectAtIndex(0) as NSDictionary).objectForKey("id") as NSString)+"\n"
                trackURIs += trackURI
                matchedTracks++
                
            }else{
                let notFoundEntry = "\(trackName)\t-\t\(artistName)\n"
                notFoundURIs += notFoundEntry
                notFoundTracks++
            }
            
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.statusLabel.stringValue = "\(matchedTracks+notFoundTracks)/\(totalTracks)\t\(notFoundTracks) tracks not found";
                self.progressIndicator.doubleValue = (Double(Double(matchedTracks+notFoundTracks)/Double(totalTracks)))*100.0;
            }
            
        })
        
    }
    
    
}

