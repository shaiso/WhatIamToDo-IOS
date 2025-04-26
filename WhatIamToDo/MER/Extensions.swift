//
//  Extensions.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 02.04.2025.
//

import UIKit

// MARK: - UIColor(hex:)
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r, g, b, a: CGFloat
        switch hexSanitized.count {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        default:
            return nil
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Расширение для поиска родительского UIViewController (если нужно)
extension UIResponder {
    func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}

// MARK: Расширение для UITextField (отступ слева)
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0,
                                               width: amount,
                                               height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

extension UIViewController {
    func showTokenExpiredAlert() {
        let alert = UIAlertController(title: "The session has expired", message: "Please log in again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first,
                   let sceneDelegate = scene.delegate as? SceneDelegate,
                   let window = sceneDelegate.window {
                    // Устанавливаем экран входа как корневой
                    window.rootViewController = SignInViewController()
                    window.makeKeyAndVisible()
                }
            }
        }))
        self.present(alert, animated: true)
    }
}


/// Расширение для модели Step для преобразования строки даты в объект Date.
extension Step {
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: self.date)
    }
}
