package asfadsfdfs.sjflasdfsf.service.impl;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import asfadsfdfs.sjflasdfsf.model.Student;
import asfadsfdfs.sjflasdfsf.repository.StudentRepository;
import asfadsfdfs.sjflasdfsf.service.StudentService;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class StudentServiceImpl implements StudentService {

    private final StudentRepository studentRepository;

    @Override
    public Flux<Student> getAllStudents() {
        return studentRepository.findAll();
    }

    @Override
    public Mono<Student> getStudentById(Long id) {
        return studentRepository.findById(id);
    }

    @Override
    public Flux<Student> getStudentsByStatus(String status) {
        return studentRepository.findByStatus(status);
    }

    @Override
    public Mono<Student> createStudent(Student student) {
        student.setCreatedAt(LocalDateTime.now());
        student.setUpdatedAt(LocalDateTime.now());
        if (student.getStatus() == null || student.getStatus().isEmpty()) {
            student.setStatus("ACTIVE");
        }
        return studentRepository.save(student);
    }

    @Override
    public Mono<Student> updateStudent(Long id, Student student) {
        return studentRepository.findById(id)
                .flatMap(existingEntity -> {
                    actual.setName(student.getName());
                    actual.setLastName(student.getLastName());
                    actual.setCountry(student.getCountry());
                    if (student.getStatus() != null) {
                        existingEntity.setStatus(student.getStatus());
                    }
                    existingEntity.setUpdatedAt(LocalDateTime.now());
                    return studentRepository.save(existingEntity);
                });
    }

    @Override
    public Mono<Void> deleteStudent(Long id) {
        return studentRepository.deleteById(id);
    }

    @Override
    public Mono<Student> activateStudent(Long id) {
        return studentRepository.findById(id)
                .flatMap(student -> {
                    student.setStatus("ACTIVE");
                    student.setUpdatedAt(LocalDateTime.now());
                    return studentRepository.save(student);
                });
    }

    @Override
    public Mono<Student> deactivateStudent(Long id) {
        return studentRepository.findById(id)
                .flatMap(student -> {
                    student.setStatus("INACTIVE");
                    student.setUpdatedAt(LocalDateTime.now());
                    return studentRepository.save(student);
                });
    }

    @Override
    public Mono<Student> suspendStudent(Long id) {
        return studentRepository.findById(id)
                .flatMap(student -> {
                    student.setStatus("SUSPENDED");
                    student.setUpdatedAt(LocalDateTime.now());
                    return studentRepository.save(student);
                });
    }
}