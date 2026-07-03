package pe.edu.vallegrande.jhonsilva38.service;

import pe.edu.vallegrande.jhonsilva38.model.Students;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface StudentsService {

    Flux<Students> getAllStudentss();

    Mono<Students> getStudentsById(Long id);

    Flux<Students> getStudentssByStatus(String status);

    Mono<Students> createStudents(Students students);

    Mono<Students> updateStudents(Long id, Students students);

    Mono<Void> deleteStudents(Long id);

    Mono<Students> activateStudents(Long id);

    Mono<Students> deactivateStudents(Long id);

    Mono<Students> suspendStudents(Long id);
}