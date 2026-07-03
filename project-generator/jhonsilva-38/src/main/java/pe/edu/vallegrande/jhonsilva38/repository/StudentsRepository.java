package pe.edu.vallegrande.jhonsilva38.repository;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import pe.edu.vallegrande.jhonsilva38.model.Students;
import reactor.core.publisher.Flux;

@Repository
public interface StudentsRepository extends ReactiveCrudRepository<Students, Long> {

    Flux<Students> findByStatus(String status);
}