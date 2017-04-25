///
/// EnvironmentView.swift
///

import Foundation
import UIKit

class Environment: UIView {
    
    var animalImageViews = [(EnvironmentType, UIImageView)]()
    
    let ANIMATION_THROTTLE_COUNT = 40
    let DISPLACEMENTS: [CGFloat] = [-130, 0, 130]
    
    var aboutToSwitchEnvironment = false
    let conductor = Conductor.sharedInstance
    let type: EnvironmentType
    lazy var keyOrigins: [CGPoint] = { return self.calculateOrigins() }()
    var keyType: KeyType { return type.key }
    var weatherType: WeatherType {
        didSet { layoutWeather() }
    }
    
    weak var delegate: KeyInteractionDelegate?
    
    init(type: EnvironmentType, weatherType: WeatherType = .cloudy) {
        self.type = type
        self.weatherType = weatherType
        super.init(frame: UIScreen.main.bounds)
        self.backgroundColor = type.backgroundColor
    }
    
    // Determines the origin for each key
    func calculateOrigins() -> [CGPoint] {
        var origins: [CGPoint] = []
        let centerOrigin = (frame.width / 2 - 50, frame.height / 2 - 50)
        
        DISPLACEMENTS.forEach { yDisplacement in
            DISPLACEMENTS.forEach {  xDisplacement in
                let origin = CGPoint(
                    x: centerOrigin.0 + xDisplacement,
                    y: centerOrigin.1 + yDisplacement
                )
                origins.append(origin)
            }
        }
        return origins
    }
    
    func changeWeather(_:UITapGestureRecognizer) {
        guard let currentWeatherView = subviews.filter({ $0 is Weather }).first else { return }
        let conductor = Conductor.sharedInstance
        currentWeatherView.removeFromSuperview()
        weatherType = {
            switch weatherType {
            case .sunny:
                conductor.MIDINotes = conductor.minorPentatonic
                return .cloudy
            case .cloudy:
                conductor.MIDINotes = conductor.bluesMinor
                return .dark
            case .dark:
                conductor.MIDINotes = conductor.majorPentatonic
                return .sunny
            }
        }()
    }
    
    func returnToCurrentEnvironment() {
        for (i, v) in animalImageViews.map({ $0.1 }).enumerated() {
            UIView.animate(withDuration: 0.2) { v.alpha = i == 1 ? 1 : 0 }
        }
    }
    
    func tappedAnimal(_ sender:UITapGestureRecognizer) {
        if aboutToSwitchEnvironment {
            transitionEvironment(sender)
        } else {
            animalImageViews.map({ $0.1 }).forEach { (animal) in
                UIView.animate(withDuration: 0.2, animations: { animal.alpha = 0.7 })
            }
        }
        aboutToSwitchEnvironment = !aboutToSwitchEnvironment
    }
    
    func transitionEvironment(_ sender:UITapGestureRecognizer) {
        guard
            let accessId = sender.view?.accessibilityIdentifier,
            let transitionType = EnvironmentType(rawValue: accessId)
            else { return }
        transitionType == type ? returnToCurrentEnvironment() : transition(to: transitionType)
    }
    
    func transition(to environmentType: EnvironmentType) {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue:"transitionEnvironment"),
            object: nil,
            userInfo:["environment" : environmentType.rawValue]
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Environment Setup
private typealias EnvironmentSetup = Environment
extension EnvironmentSetup {
    
    func addTappedAnimalGestureRecognizer(view: UIImageView) {
        let tapAnimal = UITapGestureRecognizer(target: self, action: #selector(tappedAnimal))
        view.addGestureRecognizer(tapAnimal)
    }
    
    func addChangeDelaySwipeRecognizers(view: UIImageView) {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(nextDelay))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(previousDelay))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeRight)
        view.addGestureRecognizer(swipeLeft)
    }
    
    func layoutView() {
        layoutAnimals()
        layoutKeys()
        layoutWeather()
    }
    
    func layoutAnimals() {
        var types = EnvironmentType.all.filter { $0 != type }
        // Ensure the current EnvironentType's Animal is in the middle
        types.insert(type, at: 1)
        for (index, t) in types.enumerated() { layoutAnimal(t, index: index) }
    }
    
    func layoutAnimal(_ t: EnvironmentType, index: Int) {
        
        let isCurrentType = index == 1
        
        _ = UIImageView().then {
            $0.image = isCurrentType ? animalImageForDelay() : t.animalImages[0]
            $0.tag = index
            $0.accessibilityIdentifier = t.rawValue
            addSubview($0)
            animalImageViews.append((t, $0))
            $0.alpha = isCurrentType ? 1 : 0
            
            // Gesture Recognizers
            $0.isUserInteractionEnabled = true
            addTappedAnimalGestureRecognizer(view: $0)
            addChangeDelaySwipeRecognizers(view: $0)
            
            // Anchors
            $0.heightAnchor.constraint(equalToConstant: 100).isActive = true
            $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
            $0.centerYAnchor.constraint(equalTo: centerYAnchor, constant: DISPLACEMENTS[index]).isActive = true
            $0.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func layoutKeys() {
        for (index, origin) in keyOrigins.enumerated() {
            _ = Key(origin: origin, type: keyType).then {
                $0.tag = index
                $0.conductorDelegate = delegate
                $0.animationDelegate = self
                addSubview($0)
            }
        }
    }
    
    func layoutWeather() {
        let origin = CGPoint(x: frame.width - 125, y: 25)
        let changeWeatherTap = UITapGestureRecognizer(target: self, action: #selector(changeWeather))
        _ = Weather(origin: origin, type: weatherType, environmentType: type).then {
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(changeWeatherTap)
            addSubview($0)
        }
    }
}


// MARK: - Environment Delay
extension Environment {
    
    func animalImageForDelay() -> UIImage {
        if conductor.delay.isBypassed { return type.animalImages[0] }
        switch conductor.delay.time {
        case conductor.shortDelay:
            return type.animalImages[1]
        case conductor.mediumDelay:
            return type.animalImages[2]
        default:
            return type.animalImages[3]
        }
    }
    
    func nextDelay() {
        if aboutToSwitchEnvironment { return }
        conductor.nextDelay()
        animalImageViews.filter({ $0.0 == type }).first?.1.image = animalImageForDelay()
    }
    
    func previousDelay() {
        if aboutToSwitchEnvironment { return }
        conductor.previousDelay()
        animalImageViews.filter({ $0.0 == type }).first?.1.image = animalImageForDelay()
    }
}


// MARK: - Animal Sound Delegate
protocol AnimateSoundDelegate: class {
    func animateSound(_ key: Key)
    func toggleFade(_ key: Key)
}

extension Environment: AnimateSoundDelegate {
    
    func toggleFade(_ key: Key) {
        UIView.animate(withDuration: 0.1) { key.alpha = key.isPressed ? 1 : 0.7 }
        key.isPressed = !key.isPressed
    }
    
    func animateSound(_ key: Key) {
        let noteFrequency = Conductor.sharedInstance.MIDINotes[key.tag].midiNoteToFrequency()
        let keyOrigin = keyOrigins[key.tag]
        
        let circleOrigin = CGPoint(x: keyOrigin.x + 50, y: keyOrigin.y + 50)
        
        let circlePath = UIBezierPath(
            arcCenter: circleOrigin,
            radius: CGFloat(50),
            startAngle: CGFloat(0),
            endAngle: CGFloat(Double.pi * 2),
            clockwise: true
        )
        
        let circleLayer = CAShapeLayer().then {
            $0.path = circlePath.cgPath
            $0.lineWidth = 1.0
            $0.strokeColor = UIColor(red:0.31, green:0.53, blue:0.87, alpha:1.0).cgColor
            $0.fillColor = Palette.transparent.color.cgColor
            layer.insertSublayer($0, at: 0)
        }
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeColor")
        strokeAnimation.toValue = Palette.pond.color.cgColor
        strokeAnimation.duration = noteFrequency / 50
        
        var transform = CATransform3DIdentity
        transform = CATransform3DTranslate(transform, circleOrigin.x, circleOrigin.y, 0)
        transform = CATransform3DScale(transform, 10, 10, 1)
        transform = CATransform3DTranslate(transform, -circleOrigin.x, -circleOrigin.y, 0)
        
        let transformAnimation = CABasicAnimation(keyPath: "transform")
        transformAnimation.toValue = NSValue(caTransform3D: transform)
        transformAnimation.duration = noteFrequency / 50
        
        circleLayer.add(animations: [strokeAnimation, transformAnimation]) { _ in
            let delay = DispatchTime.now() + noteFrequency / 50
            DispatchQueue.main.asyncAfter(deadline: delay) {
                circleLayer.removeFromSuperlayer()
            }
        }
    }
}
