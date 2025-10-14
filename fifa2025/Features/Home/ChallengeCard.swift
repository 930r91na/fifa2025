//
//  DailyChallenge.swift
//  fifa2025
//
//  Created by Martha Heredia Andrade on 12/10/25.
//


import SwiftUI
import PhotosUI


struct ChallengeCard: View {
    let challenge: Challenge
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("+\(challenge.pointsAwarded) puntos")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .padding(.trailing, 118)
                .padding(.top, 10)
                .padding(.bottom, -15)
            
            Text(challenge.title)
                .font(Font.theme.subheadline)
                .foregroundColor(.white)
                .padding(.top, 2)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 15)
            
            Button(action: {
                if !challenge.isCompleted {
                    onComplete()
                }
            }) {
                Text(challenge.isCompleted ? "¡Completado!" : "Intenta la experiencia!")
                    .font(.system(size: 13))
                    .fontWeight(.medium)
                    .foregroundColor(challenge.isCompleted ? Color(hex: "#10154F") : .white)
                    .multilineTextAlignment(.center)
                    .frame(width: 180)
                    .padding(.vertical, 12)
                    .background(challenge.isCompleted ? Color(hex: "#B1E902") : Color(hex: "#18257E"))
                    .cornerRadius(10)
            }
            .disabled(challenge.isCompleted)
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
        .padding(.leading, 30)
        .frame(width: 240, height: 180)
        .background(Color(hex: "#2F4FFC"))
        .cornerRadius(18)
    }
}

// MARK: - PointsAnimationView (sin cambios)
struct PointsAnimationView: View {
    let points: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#B1E902"))
            
            Text("+\(points) puntos")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#B1E902"))
            
            Text("¡Desafío completado!")
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#18257E").opacity(0.95))
                .shadow(color: Color(hex: "#B1E902").opacity(0.5), radius: 20)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                offset = -20
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(1.5)) {
                opacity = 0
                offset = -40
            }
        }
    }
}

struct ChallengePopupView: View {
    let challenge: Challenge
    let onDismiss: () -> Void
    let onComplete: (UIImage, String, Int, Bool) -> Void // ⬅️ Ahora incluye rating y recommended
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var reviewText = ""
    @State private var showReviewStep = false
    @State private var rating: Int = 0
    @State private var recommended: Bool = true
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 0) {
                if !showReviewStep {
                    // Paso 1: Descripción y tomar foto
                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            Button(action: onDismiss) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#B1E902"))
                        
                        Text(challenge.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(challenge.detailedDescription)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineSpacing(4)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(Color(hex: "#B1E902"))
                                Text("Toma una foto de evidencia")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Image(systemName: "text.quote")
                                    .foregroundColor(Color(hex: "#B1E902"))
                                Text("Escribe una reseña")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Color(hex: "#B1E902"))
                                Text("+\(challenge.pointsAwarded) puntos")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18))
                                Text("Tomar foto")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#18257E"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#B1E902"))
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                    .frame(width: 340)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#1738EA"), Color(hex: "#18257E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: Color(hex: "#1738EA").opacity(0.3), radius: 20)
                } else {
                    // Paso 2: Agregar reseña MEJORADO
                    ScrollView {
                        VStack(spacing: 24) {
                            HStack {
                                Button(action: {
                                    showReviewStep = false
                                    selectedImage = nil
                                    reviewText = ""
                                    rating = 0
                                    recommended = true
                                }) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Button(action: onDismiss) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Foto tomada
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(hex: "#B1E902"), lineWidth: 2)
                                    )
                                    .shadow(color: Color(hex: "#B1E902").opacity(0.3), radius: 10)
                            }
                            
                            VStack(spacing: 20) {
                                // Calificación con estrellas
                                VStack(spacing: 12) {
                                    Text("¿Cómo calificarías tu experiencia?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 12) {
                                        ForEach(1...5, id: \.self) { star in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3)) {
                                                    rating = star
                                                }
                                            }) {
                                                Image(systemName: star <= rating ? "star.fill" : "star")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(star <= rating ? Color(hex: "#B1E902") : .white.opacity(0.3))
                                                    .scaleEffect(star == rating ? 1.2 : 1.0)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                                
                                // Recomendación
                                VStack(spacing: 12) {
                                    Text("¿Lo recomendarías?")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 16) {
                                        // Sí
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                recommended = true
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "hand.thumbsup.fill")
                                                    .font(.system(size: 20))
                                                Text("Sí")
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                            .foregroundColor(recommended ? Color(hex: "#18257E") : .white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(recommended ? Color(hex: "#B1E902") : Color.white.opacity(0.2))
                                            .cornerRadius(12)
                                        }
                                        
                                        // No
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                recommended = false
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "hand.thumbsdown.fill")
                                                    .font(.system(size: 20))
                                                Text("No")
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                            .foregroundColor(!recommended ? .white : .white.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(!recommended ? Color.red.opacity(0.7) : Color.white.opacity(0.2))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                                
                                // Reseña escrita
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Cuéntanos tu experiencia")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    ZStack(alignment: .topLeading) {
                                        if reviewText.isEmpty {
                                            Text("Escribe aquí tu reseña detallada...")
                                                .foregroundColor(.white.opacity(0.4))
                                                .padding(.top, 8)
                                                .padding(.leading, 12)
                                        }
                                        
                                        TextEditor(text: $reviewText)
                                            .frame(height: 120)
                                            .padding(8)
                                            .foregroundColor(.white)
                                            .scrollContentBackground(.hidden)
                                            .background(Color.clear)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.15))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "#B1E902").opacity(0.3), lineWidth: 1.5)
                                    )
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Botón de completar
                            Button(action: {
                                guard let image = selectedImage,
                                      !reviewText.isEmpty,
                                      rating > 0 else { return }
                                onComplete(image, reviewText, rating, recommended)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Completar desafío")
                                        .font(.system(size: 18, weight: .bold))
                                }
                                .foregroundColor(Color(hex: "#18257E"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    isFormValid() ?
                                    Color(hex: "#B1E902") :
                                    Color.gray.opacity(0.5)
                                )
                                .cornerRadius(14)
                                .shadow(
                                    color: isFormValid() ? Color(hex: "#B1E902").opacity(0.5) : .clear,
                                    radius: 10
                                )
                            }
                            .disabled(!isFormValid())
                            .padding(.horizontal, 30)
                            .padding(.bottom, 30)
                        }
                    }
                    .frame(width: 360, height: 650)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#1738EA"), Color(hex: "#18257E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: Color(hex: "#1738EA").opacity(0.3), radius: 20)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, onImageSelected: {
                showReviewStep = true
            })
        }
    }
    private func isFormValid() -> Bool {
        return selectedImage != nil && !reviewText.isEmpty && rating > 0
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: () -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageSelected()
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
