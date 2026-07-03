package asfadsfdfs.sjflasdfsf.service;

import asfadsfdfs.sjflasdfsf.model.Student;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface StudentService {

    Flux<Student> getAllStudents();

    Mono<Student> getStudentById(Long id);

    Flux<Student> getStudentsByStatus(String status);

    Mono<Student> createStudent(Student student);

    Mono<Student> updateStudent(Long id, Student student);

    Mono<Void> deleteStudent(Long id);

    Mono<Student> activateStudent(Long id);

    Mono<Student> deactivateStudent(Long id);

    Mono<Student> suspendStudent(Long id);
}