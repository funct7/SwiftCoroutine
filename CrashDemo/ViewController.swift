//
//  ViewController.swift
//  CrashDemo
//
//  Created by Josh Woomin Park on 2021/01/31.
//  Copyright © 2021 Alex Belozierov. All rights reserved.
//

import UIKit
import SwiftCoroutine

class ViewController: UIViewController {
    
    @IBOutlet var label: UILabel!
    
    @IBOutlet var button: UIButton!
    
    @IBAction func observeAction(_ sender: UIButton) {
        reactor.observe()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        reactor = .init(
            repository: .shared,
            viewController: self)
    }
    
    func showInt(_ value: Int) {
        label.text = "\(value)"
    }
    
    func showError(_ error: Error) {
        label.text = error.localizedDescription
    }
    
    private var reactor: Reactor!

}

class Reactor {
    
    func observe() {
        let channel = repository.observe().added(to: scope)
        mainScheduler.startCoroutine(in: scope) { [weak self] in
            do {
                while !channel.isClosed {
                    let value = try channel.awaitReceive()
                    self?.viewController.showInt(value)
                }
            } catch {
                self?.viewController.showError(error)
            }
        }
    }
    
    private let mainScheduler: CoroutineScheduler = DispatchQueue.main
    private let repository: SomeRepository
    private let scope = CoScope()
    
    private unowned let viewController: ViewController
    
    init(
        repository: SomeRepository,
        viewController: ViewController)
    {
        self.repository = repository
        self.viewController = viewController
        printSelf(prefix: "INIT")
    }
    
    private func printSelf(prefix: String = "") {
        print(">> \(prefix) \(self)\(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    deinit { printSelf(prefix: "DEINIT") }
    
}

class SomeRepository {
    
    static let shared: SomeRepository = .init()
    
    private init() { }
    
    private var intChannel: CoChannel<Int>!
    
    func observe() -> CoChannel<Int> {
        if intChannel != nil { return intChannel }
        
        intChannel = .init()
        
        DispatchQueue.global().startCoroutine { [intChannel] in
            while true {
                try! Coroutine.delay(.milliseconds(500))
                let value = Int.random(in: 0...Int.max)
                print(value)
                try! intChannel!.awaitSend(value)
            }
        }
        
        return intChannel
    }
    
}
