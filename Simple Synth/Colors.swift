//
//  Colors.swift
//  Simple Synth
//
//  Created by Benjamin Bernstein on 3/29/17.
//  Copyright © 2017 Burning Flowers. All rights reserved.
//

import UIKit

enum Palette {
    case purple, blue, green, yellow, orange, red, transparent, lilypad, pond, grass, flower, petal, pistal, pistalRim
    
    var color: UIColor {
        switch self {
        case .purple: return UIColor(hex: 0x4B0082)
        case .blue: return UIColor(hex: 0x0000FF)
        case .green: return UIColor(hex: 0x00FF00)
        case .yellow: return UIColor(hex: 0xFFFF00)
        case .orange: return UIColor(hex: 0xFF7F00)
        case .red: return UIColor(hex: 0xFF0000)
        case .transparent: return UIColor(white: 1, alpha: 0.0)
        // Bird Environment
        case .flower: return UIColor.white
        case .petal: return UIColor(hex : 0xD6D2EE)
        case .grass: return UIColor(hex: 0x54C502)
        case .pistal: return UIColor(hex: 0xFC8F68)
        case .pistalRim: return UIColor(hex: 0xF3CF3C)
        // Frog Environment
        case .lilypad: return UIColor(hex: 0x7DC084)
        case .pond: return UIColor(hex: 0x69A1F7)
        }
    }
    
    static func backgroundColor(for environmentType: EnvironmentType) -> UIColor {
        switch environmentType {
        case .frog: return Palette.pond.color
        case .bird: return Palette.grass.color
        }
    }
    
    static func color(for shape: ShapeType) -> UIColor {
        switch shape {
        case .lilypad: return Palette.lilypad.color
        case .flower: return Palette.flower.color
        }
    }
}

extension UIColor {
    
    static let colors = [Palette.purple.color, Palette.blue.color, Palette.green.color, Palette.yellow.color, Palette.orange.color, Palette.red.color, Palette.purple.color, Palette.blue.color, Palette.green.color ]
    
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
    
    class func forGradient(_ red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1.0)
    }
}
