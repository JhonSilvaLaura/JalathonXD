package pe.edu.vallegrande.jhonsilva38.rest;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import pe.edu.vallegrande.jhonsilva38.model.Students;
import pe.edu.vallegrande.jhonsilva38.service.StudentsService;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/studentses")

@RequiredArgsConstructor
public class StudentsRest {

    private final StudentsService studentsService;

    @GetMapping
    public Flux<Students> getAll(@RequestParam(required = false) String status) {
        if (status != null && !status.isEmpty()) {
            return studentsService.getStudentssByStatus(status);
        }
        return studentsService.getAllStudentss();
    }

    @GetMapping("/{id}")
    public Mono<Students> getById(@PathVariable Long id) {
        return studentsService.getStudentsById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<Students> create(@RequestBody Students students) {
        return studentsService.createStudents(students);
    }

    @PutMapping("/{id}")
    public Mono<Students> update(@PathVariable Long id, @RequestBody Students students) {
        return studentsService.updateStudents(id, students);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable Long id) {
        return studentsService.deleteStudents(id);
    }

    @PatchMapping("/{id}/activate")
    public Mono<Students> activate(@PathVariable Long id) {
        return studentsService.activateStudents(id);
    }

    @PatchMapping("/{id}/deactivate")
    public Mono<Students> deactivate(@PathVariable Long id) {
        return studentsService.deactivateStudents(id);
    }

    @PatchMapping("/{id}/suspend")
    public Mono<Students> suspend(@PathVariable Long id) {
        return studentsService.suspendStudents(id);
    }
}