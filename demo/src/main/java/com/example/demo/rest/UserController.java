package com.example.demo.rest;

import com.example.demo.model.User;
import com.example.demo.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class UserController {
    
    private final UserService userService;
    
    @GetMapping
    public Flux<User> getAllUsers(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String status) {
        
        if (name != null && !name.isEmpty()) {
            return userService.searchUsersByName(name);
        }
        if (status != null && !status.isEmpty()) {
            return userService.getUsersByStatus(status);
        }
        return userService.getAllUsers();
    }
    
    @GetMapping("/{id}")
    public Mono<User> getUserById(@PathVariable Long id) {
        return userService.getUserById(id);
    }
    
    @GetMapping("/username/{username}")
    public Mono<User> getUserByUsername(@PathVariable String username) {
        return userService.getUserByUsername(username);
    }
    
    @GetMapping("/email/{email}")
    public Mono<User> getUserByEmail(@PathVariable String email) {
        return userService.getUserByEmail(email);
    }
    
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<User> createUser(@RequestBody User user) {
        return userService.createUser(user);
    }
    
    @PutMapping("/{id}")
    public Mono<User> updateUser(@PathVariable Long id, @RequestBody User user) {
        return userService.updateUser(id, user);
    }
    
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteUser(@PathVariable Long id) {
        return userService.deleteUser(id);
    }
    
    @PatchMapping("/{id}/activate")
    public Mono<User> activateUser(@PathVariable Long id) {
        return userService.activateUser(id);
    }
    
    @PatchMapping("/{id}/deactivate")
    public Mono<User> deactivateUser(@PathVariable Long id) {
        return userService.deactivateUser(id);
    }
    
    @PatchMapping("/{id}/suspend")
    public Mono<User> suspendUser(@PathVariable Long id) {
        return userService.suspendUser(id);
    }
}

