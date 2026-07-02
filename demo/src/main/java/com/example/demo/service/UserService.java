package com.example.demo.service;

import com.example.demo.model.User;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface UserService {

    Flux<User> getAllUsers();

    Mono<User> getUserById(Long id);

    Flux<User> searchUsersByName(String name);

    Flux<User> getUsersByStatus(String status);

    Mono<User> getUserByUsername(String username);

    Mono<User> getUserByEmail(String email);

    Mono<User> createUser(User user);

    Mono<User> updateUser(Long id, User user);

    Mono<Void> deleteUser(Long id);

    Mono<User> activateUser(Long id);

    Mono<User> deactivateUser(Long id);

    Mono<User> suspendUser(Long id);
}
