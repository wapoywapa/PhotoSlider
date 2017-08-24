//
//  ImageView.swift
//
//  Created by nakajijapan on 3/29/15.
//  Copyright (c) 2015 net.nakajijapan. All rights reserved.
//

import UIKit
import Kingfisher
import SimpleButton


protocol PhotoSliderImageViewDelegate {
    func photoSliderImageViewDidEndZooming(_ viewController: PhotoSlider.ImageView, atScale scale: CGFloat)
}

class ImageView: UIView {
    
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    var progressView: PhotoSlider.ProgressView!
    var delegate: PhotoSliderImageViewDelegate? = nil
    weak var imageLoader: PhotoSlider.ImageLoader?
    var isPrivatePhoto: Bool = false
    //var requestPrivatePhotosButton: BFPaperButton!
    
    
    //CUSTOM: removed initialize() from here, calling manually outside
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    //CUSTOM: added
    convenience init(frame: CGRect, isPrivatePhoto: Bool) {
        self.init(frame: frame)
        self.isPrivatePhoto = isPrivatePhoto
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initialize()
    }
    
    func initialize() {
        
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = true
        
        // for zoom
        scrollView = UIScrollView(frame: self.bounds)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.bounces = true
        scrollView.delegate  = self
        
        // image
        imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        addSubview(scrollView)
        layoutScrollView()
        
        scrollView.addSubview(imageView)
        
        // progress view
        progressView = ProgressView(frame: CGRect.zero)
        progressView.isHidden = true
        addSubview(progressView)
        layoutProgressView()
        
        
        imageView.autoresizingMask = [
            .flexibleWidth,
            .flexibleLeftMargin,
            .flexibleRightMargin,
            .flexibleTopMargin,
            .flexibleHeight,
            .flexibleBottomMargin
        ]
        
        //CUSTOM:
        if self.isPrivatePhoto
        {
            let privateRequestView = UIView(frame: self.scrollView.frame)
            privateRequestView.backgroundColor = UIColor(red: 41.0 / 255.0, green: 44.0 / 255.0, blue: 49.0 / 255.0, alpha: 1.0)

            let requestButton = SimpleButton(type: .custom)
            requestButton.frame = CGRect(x: 16, y: (scrollView.frame.size.height / 2) + 20, width: scrollView.frame.size.width - 32, height: 50.0)
            requestButton.setTitle(NSLocalizedString("Request private photos", comment: "Request private photos").uppercased(), for: .normal)
            requestButton.setTitleColor(UIColor.white, for: .normal)
            requestButton.setBackgroundColor(UIColor(red: 72.0 / 255.0, green: 96.0 / 255.0, blue: 1.0, alpha: 1.0), for: .normal)
            requestButton.addTarget(self, action: #selector(requestButtonTapped), for: .touchUpInside)
            
            scrollView.addSubview(privateRequestView)
            privateRequestView.addSubview(requestButton)
        }
        else
        {
            let doubleTabGesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
            doubleTabGesture.numberOfTapsRequired = 2
            addGestureRecognizer(doubleTabGesture)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let boundsSize = self.bounds.size
        var frameToCenter = self.imageView.frame
        
        // Horizontally
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2.0)
        } else {
            frameToCenter.origin.x = 0
        }
        
        // Vertically
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2.0)
        } else {
            frameToCenter.origin.y = 0
        }
        
        // Center
        if !(imageView.frame.equalTo(frameToCenter)) {
            imageView.frame = frameToCenter
        }
    }
    
    func requestButtonTapped()
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "uk.co.wapoapp.requestprivates"), object: self, userInfo: nil)
    }
    
    
    // MARK: - Constraints
    
    private func layoutScrollView() {
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        [
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 0.0),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0.0),
            scrollView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0.0),
            ].forEach { $0.isActive = true }
    }
    
    private func layoutProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        [
            progressView.heightAnchor.constraint(equalToConstant: 40.0),
            progressView.widthAnchor.constraint(equalToConstant: 40.0),
            progressView.centerXAnchor.constraint(lessThanOrEqualTo: centerXAnchor, constant: 1.0),
            progressView.centerYAnchor.constraint(lessThanOrEqualTo: centerYAnchor, constant: 1.0),
            ].forEach { $0.isActive = true }
    }
    
    func loadImage(imageURL: URL) {
        progressView.isHidden = false
        imageLoader?.load(
            imageView: imageView,
            fromURL: imageURL,
            progress: { [weak self] (receivedSize, totalSize) in
                let progress: Float = Float(receivedSize) / Float(totalSize)
                self?.progressView.animateCurveToProgress(progress: progress)
            },
            completion: { [weak self] (image) in
                self?.progressView.isHidden = true
                if let image = image {
                    self?.layoutImageView(image: image)
                }
            }
        )
    }
    
    func setImage(image:UIImage) {
        imageView.image = image
        layoutImageView(image: image)
    }
    
    func layoutImageView(image:UIImage) {
        var frame = CGRect.zero
        frame.origin = CGPoint.zero
        
        let height = image.size.height * (bounds.width / image.size.width)
        let width = image.size.width * (bounds.height / image.size.height)
        
        if image.size.width > image.size.height {
            
            frame.size = CGSize(width: bounds.width, height: height)
            if height >= bounds.height {
                frame.size = CGSize(width: width, height: bounds.height)
            }
            
        } else {
            
            frame.size = CGSize(width: width, height: bounds.height)
            if width >= bounds.width {
                frame.size = CGSize(width: bounds.width, height: height)
            }
            
        }
        
        imageView.frame = frame
        imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func layoutImageView() {
        
        guard let image = self.imageView.image else {
            return
        }
        layoutImageView(image: image)
    }
}

// MARK: - Actions

extension ImageView {
    
    func didDoubleTap(_ sender: UIGestureRecognizer) {
        if scrollView.zoomScale == 1.0 {
            let touchPoint = sender.location(in: self)
            scrollView.zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
        } else {
            scrollView.setZoomScale(0.0, animated: true)
        }
    }
    
}

// MARK: - UIScrollViewDelegate

extension ImageView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.photoSliderImageViewDidEndZooming(self, atScale: scale)
    }
    
}
