export interface UserType {
  id: number;
  name: string;
  email: string;
}

export class User implements UserType {
  id: number;
  name: string;
  email: string;

  constructor(id: number, name: string, email: string) {
    this.id = id;
    this.name = name;
    this.email = email;
  }
}

//const user = new User(1, "John Doe", "john@example.com");
