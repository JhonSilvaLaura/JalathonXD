package asfadsfdfs.sjflasdfsf.repository;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import asfadsfdfs.sjflasdfsf.model.Student;
import reactor.core.publisher.Flux;

@Repository
public interface StudentRepository extends ReactiveCrudRepository<Student, Long> {

    Flux<Student> findByStatus(String status);
}