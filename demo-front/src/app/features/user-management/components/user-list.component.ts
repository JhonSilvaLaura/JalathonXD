import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserService } from '../../../core/services/user.service';
import { User } from '../../../core/interfaces/user.interface';

@Component({
  selector: 'app-user-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss']
})
export class UserListComponent implements OnInit {
  private userService = inject(UserService);
  
  users = signal<User[]>([]);
  selectedUser = signal<User | null>(null);
  isEditing = signal(false);
  searchTerm = signal('');
  
  newUser: User = {
    username: '',
    email: '',
    firstName: '',
    lastName: '',
    phone: '',
    address: ''
  };

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    this.userService.getAllUsers().subscribe({
      next: (users) => this.users.set(users),
      error: (err) => console.error('Error loading users:', err)
    });
  }

  searchUsers() {
    if (this.searchTerm().trim()) {
      this.userService.searchUsers(this.searchTerm()).subscribe({
        next: (users) => this.users.set(users),
        error: (err) => console.error('Error searching users:', err)
      });
    } else {
      this.loadUsers();
    }
  }

  selectUser(user: User) {
    this.selectedUser.set({ ...user });
    this.isEditing.set(true);
  }

  createUser() {
    if (this.newUser.username && this.newUser.email && this.newUser.firstName && this.newUser.lastName) {
      this.userService.createUser(this.newUser).subscribe({
        next: () => {
          this.loadUsers();
          this.resetForm();
        },
        error: (err) => console.error('Error creating user:', err)
      });
    }
  }

  updateUser() {
    const user = this.selectedUser();
    if (user && user.id) {
      this.userService.updateUser(user.id, user).subscribe({
        next: () => {
          this.loadUsers();
          this.cancelEdit();
        },
        error: (err) => console.error('Error updating user:', err)
      });
    }
  }

  deleteUser(id: number | undefined) {
    if (id && confirm('¿Estás seguro de eliminar este usuario?')) {
      this.userService.deleteUser(id).subscribe({
        next: () => this.loadUsers(),
        error: (err) => console.error('Error deleting user:', err)
      });
    }
  }

  changeStatus(id: number | undefined, action: 'activate' | 'deactivate' | 'suspend') {
    if (!id) return;

    const statusActions = {
      activate: () => this.userService.activateUser(id),
      deactivate: () => this.userService.deactivateUser(id),
      suspend: () => this.userService.suspendUser(id)
    };

    statusActions[action]().subscribe({
      next: () => this.loadUsers(),
      error: (err) => console.error(`Error changing status to ${action}:`, err)
    });
  }

  cancelEdit() {
    this.selectedUser.set(null);
    this.isEditing.set(false);
  }

  resetForm() {
    this.newUser = {
      username: '',
      email: '',
      firstName: '',
      lastName: '',
      phone: '',
      address: ''
    };
  }

  getStatusIcon(status?: string): string {
    switch (status) {
      case 'ACTIVE':
        return 'fas fa-check-circle';
      case 'INACTIVE':
        return 'fas fa-times-circle';
      case 'SUSPENDED':
        return 'fas fa-pause-circle';
      default:
        return 'fas fa-question-circle';
    }
  }
}
