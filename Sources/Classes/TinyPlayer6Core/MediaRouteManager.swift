//
//  AirplayManager.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 19/01/2017.
//  Copyright © 2017 Xi Chen. All rights reserved.
//

#if os(iOS)

import AVFoundation
import MediaPlayer

/**
     For iOS devices, TinyVideoPlayer can detect three media routing modes:
     
     - airplayPlayback: Media is routed to an Airplay capable device. The video content is *only* rendered on
     this device, and video rendering on the iOS device is completely off.
     
     - airplayPlaybackMirroring: The screen of the iOS device is mirrored to the Airplay capable device.
     The video content is rendered on *both* devices.
     
     - routeOff: Media routing is off. Video is playing on the iOS device.
 */
public enum MediaRouteState {
    case airplayPlayback
    case airplayPlaybackMirroring
    case routeOff
}

/**
     This manager can be used as a standalone component in your project to observe
     and react to media route change events.
 */
public final class MediaRouteManager: TinyLogging, @unchecked Sendable {
    
    /* The single acess point of this component. */
    public static let sharedManager = MediaRouteManager()
    
    /* Register as a delegate to receive MediaRouteManagerDelegate callbacks. */
    public weak var delegate: MediaRouteManagerDelegate?
    
    /* This closure is called whenever the route state is changed. */
    public var onStateChangeClosure: ((_ routeState: MediaRouteState) -> Void)?
    
    /*
        This closure is called whenever the availability of media routing is changed.
        E.g. An Airplay capable device is deteced in the local network.
     */
    public var onAvailablityChangeClosure: ((_ available: Bool) -> Void)?
    
    /* */
    public var mediaRouteState: MediaRouteState = .routeOff {
        didSet {
            delegate?.mediaRouteStateHasChangedTo(state: self.mediaRouteState)
        }
    }
    
    public var loggingLevel: TinyLoggingLevel = .info
    
    private var volumnView: MPVolumeView! = nil
  
    private var routesDetector: AVRouteDetector! = nil
    
    private init() {
        
        DispatchQueue.main.sync {
            self.volumnView = MPVolumeView(frame: .zero)
            self.routesDetector = AVRouteDetector()
            
            routesDetector.isRouteDetectionEnabled = true
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.ExternalPlaybackStateChanged,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: { [unowned self] _ in
                                                
                                                    var newState: MediaRouteState = self.mediaRouteState
                                                
                                                    if self.isAirPlayConnected {
                                                        
                                                        if self.isAirPlayPlaybackActive {
                                                            
                                                            newState = .airplayPlayback
                                                            self.verboseLog("Airplay playback activated!")
                                                            
                                                        } else if self.isAirplayMirroringActive {
                                                            
                                                            newState = .airplayPlaybackMirroring
                                                            self.verboseLog("Airplay playback mirroring activated!")
                                                        }

                                                    } else {
                                                        
                                                        newState = .routeOff
                                                        self.verboseLog("External playback deactivated!")
                                                    }
                                                
                                                    self.delegate?.mediaRouteStateHasChangedTo(state: newState)
                                                
                                                    self.onStateChangeClosure?(newState)
                                               })

        NotificationCenter.default.addObserver(forName: NSNotification.Name.ExternalPlaybackStateChanged,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: { @Sendable [unowned self] _ in
            
            DispatchQueue.main.sync {
                self.delegate?.wirelessRouteAvailabilityChanged(available: self.routesDetector.multipleRoutesDetected)
            }
            
            DispatchQueue.main.sync {
                self.onAvailablityChangeClosure?(self.routesDetector.multipleRoutesDetected)
            }
        })
    }
  
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /**
        This read-only variable tells generally wether the current media playback is routed via Airplay.
     */
    public var isAirPlayConnected: Bool {
        DispatchQueue.main.sync {
            return self.routesDetector.multipleRoutesDetected
        }
    }

    /**
        This read-only variable tells wether the current media playback is routed wirelessly via mirroring mode.
     */
    public var isAirplayMirroringActive: Bool {
        
        if isAirPlayConnected {
            return DispatchQueue.main.sync {
                let screens = UIScreen.screens
                if screens.count > 1 {
                    return screens[1].mirrored == UIScreen.main
                } else {
                    return false
                }
            }
        }
        
        return false
    }

    /**
        This read-only variable tells wether the current video stream is routed to an Airplay capable device.
     */
    public var isAirPlayPlaybackActive: Bool {
        
        return isAirPlayConnected && !isAirplayMirroringActive
    }

    /**
        This read-only variable tells wether the current video stream is routed via a HDMI cable.
     */
    public var isWiredPlaybackActive: Bool {
        return DispatchQueue.main.sync {
            if isAirPlayPlaybackActive {
                return false
            }
            
            let screens = UIScreen.screens
            if screens.count > 1 {
                return screens[1].mirrored == UIScreen.main
            } else {
                return false
            }
        }
        
    }
}

public protocol MediaRouteManagerDelegate: AnyObject {
    
    var mediaRouteManager: MediaRouteManager { get }
    
    /**
        This delegate method gets called whenever the media route state is changed.
        This can be a consequence of switching on/off Airplay or connect to a external display with a HDMI cable.
     */
    func mediaRouteStateHasChangedTo(state: MediaRouteState)
    
    /**
        This delegate methods gets called when the system detects that there is an external
        playback device (Bluetooth, Airplay) becomes available/unavailable in the local connectivity.
     */
    func wirelessRouteAvailabilityChanged(available: Bool)
}

#endif
