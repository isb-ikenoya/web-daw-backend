import {
  JsonController,
  Param,
  QueryParam,
  Body,
  Get,
  Post,
  Put,
  Delete,
  UseBefore,
  HttpCode,
} from "routing-controllers";
import { checkJwt } from "../utils/auth0";

@JsonController()
@UseBefore(checkJwt)
export class UserController {
  @Get("/users")
  @HttpCode(200)
  getUserAll() {
    return "This action returns all users";
  }

  @Get("/user")
  getUser(@QueryParam("id") id: number) {
    return "This action returns user #" + id;
  }

  @Post("/user")
  createUser(user: any) {
    return "Saving user...";
  }

  @Put("/user/:id")
  updateUser(@Param("id") id: number, @Param("user") user: any) {
    return "Updating a user...";
  }

  @Delete("/user/:id")
  deleteUser(@Param("id") id: number) {
    return "Removing user...";
  }
}
