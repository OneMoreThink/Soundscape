//
//  ARVisualizationViewModel.swift
//  Soundscape
//
//  Created by 이종선 on 2/12/25.
//

import Combine
import Foundation

final class ARVisualizationViewModel: ObservableObject {
    @Published private(set) var currentAmplitude: Float = 0
    @Published private(set) var error: Error?
    
    private let audioSystem = AudioSystem()
    private var cancellables = Set<AnyCancellable>()
    
    init(){
        // 오디오 스트림 구독
        audioSystem.audioStream
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
            },
            receiveValue: { [weak self] audioData in
                self?.currentAmplitude = audioData.amplitude
                }
            )
            .store(in: &cancellables)
    }
    
    func startAudioCapture() {
        do {
            try audioSystem.start()
        } catch {
            self.error = error
        }
    }
    
    func stopAudioCapture() {
        audioSystem.stop()
    }
}
