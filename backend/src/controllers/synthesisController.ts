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
  Res,
  QueryParams,
} from "routing-controllers";
import { checkJwt } from "../utils/auth0";
import { audioQuery } from "../api/voicevox/synthesis/endpoints/create-query";
import { synthesis } from "../api/voicevox/synthesis/endpoints/speech-synthesis";
import { Response } from "express";
import { z } from "zod";

const SynthesisSchema = z.object({
  speaker: z.coerce.number().int().positive().default(0),
  text: z
    .string({
      message: "Text is required",
    })
    .min(1),
});

type Synthesis = z.infer<typeof SynthesisSchema>;

@JsonController()
@UseBefore(checkJwt)
export class SynthesisController {
  @Post("/talk_synthesis")
  @HttpCode(200)
  async talkSynthesis(@QueryParams() req: Synthesis, @Res() response: Response) {
    try {
      const result = SynthesisSchema.safeParse(req);
      console.log(result);

      if (!result.success) {
        //throw new Error("同期エラーが発生しました");
        if (result.error instanceof z.ZodError) {
          return response.status(400).json({
            error: "Validation failed",
            details: result.error.issues.map((issue) => ({
              path: issue.path.join("."),
              message: issue.message,
            })),
          });
        }
      }

      const audioQueryRes = await audioQuery({
        speaker: req.speaker,
        text: req.text,
      });

      const defaultAudioQuery = audioQueryRes.data;

      const res = await synthesis(
        defaultAudioQuery,
        { speaker: req.speaker },
        { responseType: "arraybuffer" }
      );

      const audioData = res.data as unknown as ArrayBuffer;

      // 3. レスポンスヘッダーの設定とバイナリの返却
      response.setHeader("Content-Type", "audio/wav");

      // Bufferに変換して送信
      return response.send(Buffer.from(audioData));
    } catch (err) {
      console.log(err);
      response.status(500).json({ message: "intenal server error" });
    }
  }
}
