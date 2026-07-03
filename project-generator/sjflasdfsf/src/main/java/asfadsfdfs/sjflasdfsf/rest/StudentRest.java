package asfadsfdfs.sjflasdfsf.rest;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import asfadsfdfs.sjflasdfsf.model.Student;
import asfadsfdfs.sjflasdfsf.service.StudentService;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/studentes")

@RequiredArgsConstructor
public class StudentRest {

    private final StudentService studentService;

    @GetMapping
    public Flux<Student> getAll(@RequestParam(required = false) String status) {
        if (status != null && !status.isEmpty()) {
            return studentService.getStudentsByStatus(status);
        }
        return studentService.getAllStudents();
    }

    @GetMapping("/{id}")
    public Mono<Student> getById(@PathVariable Long id) {
        return studentService.getStudentById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<Student> create(@RequestBody Student student) {
        return studentService.createStudent(student);
    }

    @PutMapping("/{id}")
    public Mono<Student> update(@PathVariable Long id, @RequestBody Student student) {
        return studentService.updateStudent(id, student);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable Long id) {
        return studentService.deleteStudent(id);
    }

    @PatchMapping("/{id}/activate")
    public Mono<Student> activate(@PathVariable Long id) {
        return studentService.activateStudent(id);
    }

    @PatchMapping("/{id}/deactivate")
    public Mono<Student> deactivate(@PathVariable Long id) {
        return studentService.deactivateStudent(id);
    }

    @PatchMapping("/{id}/suspend")
    public Mono<Student> suspend(@PathVariable Long id) {
        return studentService.suspendStudent(id);
    }
}