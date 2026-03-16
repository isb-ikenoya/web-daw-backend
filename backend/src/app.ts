import path from "path";
import dotenv from "dotenv";

// NODE_ENVの設定に基づいて.envファイルを選択
const envFile = path.resolve(
  __dirname,
  `../envs/.env.${process.env.NODE_ENV}.local`,
);
// 環境変数を読み込み
dotenv.config({ path: envFile });

import express, { NextFunction, Request, Response, Router } from "express";
import { useExpressServer } from "routing-controllers";
import { UserController } from "./controllers/userController";
import "reflect-metadata";
import cors from "cors";
import { checkJwt } from "./utils/auth0";
import bodyParser from "body-parser";
import { SynthesisController } from "./controllers/synthesisController";

const app = express();
const port = 3000;

// ミドルウェア設定
app.use(express.json());
app.use(cors({ origin: true }));
app.use(bodyParser.json());
app.use(
  bodyParser.urlencoded({
    extended: true,
  }),
);

useExpressServer(app, {
  // 全てのコントローラーの先頭に "/api" を付与します
  routePrefix: "/api",
  controllers: [UserController, SynthesisController],
  middlewares: [checkJwt],
  defaultErrorHandler: false,
});

// エラーハンドリング
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error("エラーメッセージ:", err.message);
  if (err.name === "UnauthorizedError") {
    // 認証エラーの場合は403
    res.status(403).json({ message: "認証エラー: アクセスが拒否されました。" });
  } else {
    res.status(500).json({ message: "不明なエラーが発生しました。" });
  }
});

// サーバー起動
app.listen(port, () => {
  console.log(process.env.AUTH0_AUDIENCE);
  console.log(process.env.AUTH0_DOMAIN);
  console.log(`Server is running at http://localhost:${port}`);
});

export default app;
