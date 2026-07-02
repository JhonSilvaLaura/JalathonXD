package com.example.demo.service.impl;

import com.example.demo.model.User;
import com.example.demo.repository.UserRepository;
import com.example.demo.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    
    private final UserRepository userRepository;
    
    @Override
    public Flux<User> getAllUsers() {
        return userRepository.findAll();
    }
    
    @Override
    public Mono<User> getUserById(Long id) {
        return userRepository.findById(id);
    }
    
    @Override
    public Flux<User> searchUsersByName(String name) {
        return userRepository.findByFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCase(name, name);
    }
    
    @Override
    public Flux<User> getUsersByStatus(String status) {
        return userRepository.findByStatus(status);
    }
    
    @Override
    public Mono<User> getUserByUsername(String username) {
        return userRepository.findByUsername(username);
    }
    
    @Override
    public Mono<User> getUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }
    
    @Override
    public Mono<User> createUser(User user) {
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        if (user.getStatus() == null || user.getStatus().isEmpty()) {
            user.setStatus("ACTIVE");
        }
        return userRepository.save(user);
    }
    
    @Override
    public Mono<User> updateUser(Long id, User user) {
        return userRepository.findById(id)
            .flatMap(existingUser -> {
                existingUser.setUsername(user.getUsername());
                existingUser.setEmail(user.getEmail());
                existingUser.setFirstName(user.getFirstName());
                existingUser.setLastName(user.getLastName());
                existingUser.setPhone(user.getPhone());
                existingUser.setAddress(user.getAddress());
                existingUser.setStatus(user.getStatus());
                existingUser.setUpdatedAt(LocalDateTime.now());
                return userRepository.save(existingUser);
            });
    }
    
    @Override
    public Mono<Void> deleteUser(Long id) {
        return userRepository.deleteById(id);
    }
    
    @Override
    public Mono<User> activateUser(Long id) {
        return userRepository.findById(id)
            .flatMap(user -> {
                user.setStatus("ACTIVE");
                user.setUpdatedAt(LocalDateTime.now());
                return userRepository.save(user);
            });
    }
    
    @Override
    public Mono<User> deactivateUser(Long id) {
        return userRepository.findById(id)
            .flatMap(user -> {
                user.setStatus("INACTIVE");
                user.setUpdatedAt(LocalDateTime.now());
                return userRepository.save(user);
            });
    }
    
    @Override
    public Mono<User> suspendUser(Long id) {
        return userRepository.findById(id)
            .flatMap(user -> {
                user.setStatus("SUSPENDED");
                user.setUpdatedAt(LocalDateTime.now());
                return userRepository.save(user);
            });
    }
}
