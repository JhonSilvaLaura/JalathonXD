package pe.edu.vallegrande.jhonsilva38.service.impl;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import pe.edu.vallegrande.jhonsilva38.model.Students;
import pe.edu.vallegrande.jhonsilva38.repository.StudentsRepository;
import pe.edu.vallegrande.jhonsilva38.service.StudentsService;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class StudentsServiceImpl implements StudentsService {

    private final StudentsRepository studentsRepository;

    @Override
    public Flux<Students> getAllStudentss() {
        return studentsRepository.findAll();
    }

    @Override
    public Mono<Students> getStudentsById(Long id) {
        return studentsRepository.findById(id);
    }

    @Override
    public Flux<Students> getStudentssByStatus(String status) {
        return studentsRepository.findByStatus(status);
    }

    @Override
    public Mono<Students> createStudents(Students students) {
        students.setCreatedAt(LocalDateTime.now());
        students.setUpdatedAt(LocalDateTime.now());
        if (students.getStatus() == null || students.getStatus().isEmpty()) {
            students.setStatus("ACTIVE");
        }
        return studentsRepository.save(students);
    }

    @Override
    public Mono<Students> updateStudents(Long id, Students students) {
        return studentsRepository.findById(id)
                .flatMap(existingEntity -> {
                    actual.setName(students.getName());
                    actual.setLastName(students.getLastName());
                    actual.setCountry(students.getCountry());
                    actual.setEmail(students.getEmail());
                    if (students.getStatus() != null) {
                        existingEntity.setStatus(students.getStatus());
                    }
                    existingEntity.setUpdatedAt(LocalDateTime.now());
                    return studentsRepository.save(existingEntity);
                });
    }

    @Override
    public Mono<Void> deleteStudents(Long id) {
        return studentsRepository.deleteById(id);
    }

    @Override
    public Mono<Students> activateStudents(Long id) {
        return studentsRepository.findById(id)
                .flatMap(students -> {
                    students.setStatus("ACTIVE");
                    students.setUpdatedAt(LocalDateTime.now());
                    return studentsRepository.save(students);
                });
    }

    @Override
    public Mono<Students> deactivateStudents(Long id) {
        return studentsRepository.findById(id)
                .flatMap(students -> {
                    students.setStatus("INACTIVE");
                    students.setUpdatedAt(LocalDateTime.now());
                    return studentsRepository.save(students);
                });
    }

    @Override
    public Mono<Students> suspendStudents(Long id) {
        return studentsRepository.findById(id)
                .flatMap(students -> {
                    students.setStatus("SUSPENDED");
                    students.setUpdatedAt(LocalDateTime.now());
                    return studentsRepository.save(students);
                });
    }
}