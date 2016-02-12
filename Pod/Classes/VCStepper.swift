//
//  VCStepper.swift
//  VCStepper
//
//  Created by Craig Barreras on 1/2/16.
//  Copyright © 2016 Vicino. All rights reserved.
//

import UIKit

struct Observer<T> {
    let failed: ((NSError) -> ())?
    let completed: (() -> ())?
    let sendNext: ((T) -> ())?
}

struct SignalProducer<T> {
    let start: (Observer<T>) -> ()
}

protocol VCStepperDelegate {
    func stepper(stepper: VCStepper, shouldChangeValue newValue: Double) -> SignalProducer<Bool>
}

enum VCStepperButtonType {
    case Plus, Minus
}

public class VCStepper: UIControl {
    
    private var minusButton: VCStepperButton!
    private var plusButton: VCStepperButton!
    private var label: UILabel!
    
    var delegate: VCStepperDelegate?
    
    // Set this to true if you want the label to be truncated as an Int on the label
    var truncateValue = false {
        didSet {
            if truncateValue {
                label.text = String(Int(value))
            } else {
                label.text = String(_value)
            }
        }
    }
    
    private var _value: Double = 1 {
        didSet {
            if truncateValue {
                label.text = String(Int(value))
            } else {
                label.text = String(_value)
            }
            
            if _value == minimumValue {
                minusButton.enabled = false
            } else {
                minusButton.enabled = true
            }
            
            if _value == maximumValue {
                plusButton.enabled = false
            } else {
                plusButton.enabled = true
            }
        }
    }
    
    var value: Double {
        get {
            return _value
        }
        set {
            if let minimum = minimumValue where newValue < minimum {
                return
            }
            if let maximum = maximumValue where newValue > maximum {
                return
            }
            
            _value = newValue
            sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    var color: UIColor = UIColor.redColor() {
        didSet {
            setNeedsDisplay()
            minusButton.color = color
            minusButton.setNeedsDisplay()
            plusButton.color = color
            plusButton.setNeedsDisplay()
        }
    }
    
    private var _initialValue: Double = 1
    var initialValue: Double {
        get {
            return _initialValue
        }
        set {
            if let minimum = minimumValue where newValue < minimum {
                print("Attempting to set an initial value greater than the maximum value")
                return
            }
            if let maximum = maximumValue where newValue > maximum {
                print("Attempting to set an initial value less than the minimum value")
                return
            }
            _initialValue = newValue
        }
    }
    
    var minimumValue: Double? {
        didSet {
            if let minimum = minimumValue where value < minimum {
                _value = minimum
            }
        }
    }
    
    var maximumValue: Double? {
        didSet {
            if let maximum = maximumValue where value > maximum {
                _value = maximum
            }
        }
    }
    
    var incrementalValue: Double = 1 {
        willSet {
            if newValue <= 0 {
                NSException(name: NSInvalidArgumentException, reason: "The VCStepper incremental value must be greater than 0", userInfo: nil).raise()
            }
        }
    }
    
    override public func drawRect(rect: CGRect) {
        layer.masksToBounds = true
        layer.cornerRadius = 5
        layer.borderColor = color.CGColor
        layer.borderWidth = 1.5
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        backgroundColor = UIColor.clearColor()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        // minus button
        minusButton = VCStepperButton(stepperButtonType: .Minus)
        minusButton.addTarget(self, action: Selector("didTapStepperButton:"), forControlEvents: .TouchUpInside)
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        minusButton.setContentHuggingPriority(750, forAxis: .Horizontal)
        
        // plus button
        plusButton = VCStepperButton(stepperButtonType: .Plus)
        plusButton.addTarget(self, action: Selector("didTapStepperButton:"), forControlEvents: .TouchUpInside)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.setContentHuggingPriority(750, forAxis: .Horizontal)
        
        // label
        label = UILabel(frame: CGRectZero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(749, forAxis: .Horizontal)
        label.textAlignment = .Center
        if truncateValue {
            label.text = String(Int(value))
        } else {
            label.text = String(_value)
        }
        label.font = UIFont.systemFontOfSize(15)
        label.textColor = color
        
        let stackView = UIStackView(arrangedSubviews: [minusButton, label, plusButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .FillEqually
        addSubview(stackView)
        
        let views = ["stack" : stackView]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[stack]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[stack]|", options: .DirectionLeadingToTrailing, metrics: nil, views: views)
        addConstraints(horizontalConstraints)
        addConstraints(verticalConstraints)
    }
    
    @objc private func didTapStepperButton(sender: VCStepperButton) {
        let newValue: Double
        switch sender.stepperButtonType {
        case .Minus:
            if value == minimumValue {
                return
            }
            newValue = value - incrementalValue
        case .Plus:
            if value == maximumValue {
                return
            }
            newValue = value + incrementalValue
        }
        
        // if the delegate supplies a signal producer for shouldChangeValue:, then we use that here
        if let signalProducer = delegate?.stepper(self, shouldChangeValue: newValue) {
            let observer = Observer<Bool>(failed: nil, completed: nil) { (nextValue) -> () in
                if nextValue {
                    self.value = newValue
                }
            }
            signalProducer.start(observer)
            return
        }
        
        // otherwise, we just go ahead and set the new value
        self.value = newValue
    }
}

private class VCStepperButton: UIButton {
    var color = UIColor.redColor()
    var disabledColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.7)
    
    private var stepperButtonType: VCStepperButtonType
    
    init(stepperButtonType: VCStepperButtonType) {
        self.stepperButtonType = stepperButtonType
        super.init(frame: CGRectZero)
        switch stepperButtonType {
        case .Minus:
            setTitle("-", forState: .Normal)
        case .Plus:
            setTitle("+", forState: .Normal)
        }
        
        setTitleColor(color, forState: .Normal)
        setTitleColor(disabledColor, forState: .Disabled)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        switch stepperButtonType {
        case .Minus:
            addRightBorderWithRect(rect)
        case .Plus:
            addLeftBorderWithRect(rect)
        }
    }
    
    private func addLeftBorderWithRect(rect: CGRect) {
        let layer = CALayer()
        layer.frame = CGRectMake(0, 0, 1.5, rect.height)
        layer.backgroundColor = color.CGColor
        self.layer.addSublayer(layer)
    }
    
    private func addRightBorderWithRect(rect: CGRect) {
        let layer = CALayer()
        layer.frame = CGRectMake(rect.width - 1.5, 0, 1.5, rect.height)
        layer.backgroundColor = color.CGColor
        self.layer.addSublayer(layer)
    }
}
