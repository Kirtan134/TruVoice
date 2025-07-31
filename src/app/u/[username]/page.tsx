"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormMessage,
} from "@/components/ui/form";
import { Separator } from "@/components/ui/separator";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "@/components/ui/use-toast";
import { messageSchema } from "@/schemas/messageSchema";
import { ApiResponse } from "@/types/ApiResponse";
import { zodResolver } from "@hookform/resolvers/zod";
import { useCompletion } from "ai/react";
import axios, { AxiosError } from "axios";
import { Loader2 } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { useForm } from "react-hook-form";
import * as z from "zod";

const specialChar = "||";

const parseStringMessages = (messageString: string): string[] => {
  return messageString.split(specialChar);
};

const initialMessageString =
  "What's your favorite movie?||Do you have any pets?||What's your dream job?";

export default function SendMessage() {
  const params = useParams<{ username: string }>();
  const username = params.username;

  const {
    complete,
    completion,
    isLoading: isSuggestLoading,
    error,
  } = useCompletion({
    api: "/api/suggest-messages",
    initialCompletion: initialMessageString,
  });

  const form = useForm<z.infer<typeof messageSchema>>({
    resolver: zodResolver(messageSchema),
  });

  const messageContent = form.watch("content");

  const handleMessageClick = (message: string) => {
    form.setValue("content", message);
  };

  const [isLoading, setIsLoading] = useState(false);

  const onSubmit = async (data: z.infer<typeof messageSchema>) => {
    setIsLoading(true);
    try {
      const response = await axios.post<ApiResponse>("/api/send-message", {
        ...data,
        username,
      });

      toast({
        title: response.data.message,
        variant: "default",
      });
      form.reset({ ...form.getValues(), content: "" });
    } catch (error) {
      const axiosError = error as AxiosError<ApiResponse>;
      toast({
        title: "Error",
        description:
          axiosError.response?.data.message ?? "Failed to sent message",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const fetchSuggestedMessages = async () => {
    try {
      complete("");
    } catch (error) {
      console.error("Error fetching messages:", error);
      toast({
        title: "Error",
        description: "Failed to generate suggestions. Please try again.",
        variant: "destructive",
      });
    }
  };

  const [isGeneratingFeedback, setIsGeneratingFeedback] = useState(false);

  const refineMessage = async () => {
    const currentMessage = form.getValues("content");

    if (!currentMessage || currentMessage.trim().length === 0) {
      toast({
        title: "No message to refine",
        description:
          "Please write a message first, then click refine to improve it.",
        variant: "destructive",
      });
      return;
    }

    setIsGeneratingFeedback(true);
    try {
      const response = await axios.post("/api/generate-feedback", {
        message: currentMessage,
        action: "refine",
      });

      const refinedMessage = response.data.message;
      form.setValue("content", refinedMessage);

      toast({
        title: "Message Refined",
        description: "AI has improved your message!",
        variant: "default",
      });
    } catch (error) {
      console.error("Error refining message:", error);
      toast({
        title: "Error",
        description: "Failed to refine message. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsGeneratingFeedback(false);
    }
  };

  return (
    <div className="container mx-auto my-2 p-6 bg-white rounded max-w-4xl">
      <h1 className="text-3xl font-bold mb-4 text-center">
        Send Anonymous Message to @{username}
      </h1>
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <FormField
            control={form.control}
            name="content"
            render={({ field }) => (
              <FormItem>
                <FormControl>
                  <div className="relative">
                    <Textarea
                      placeholder="Write your anonymous message here"
                      className="resize-none pr-20"
                      {...field}
                    />
                    <Button
                      type="button"
                      onClick={refineMessage}
                      disabled={isGeneratingFeedback || !messageContent}
                      className="absolute top-2 right-2 h-8 px-3 text-xs bg-blue-600 hover:bg-blue-700"
                      variant="secondary"
                    >
                      {isGeneratingFeedback ? (
                        <>
                          <Loader2 className="mr-1 h-3 w-3 animate-spin" />
                          Refining...
                        </>
                      ) : (
                        "✨ Refine"
                      )}
                    </Button>
                  </div>
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <div className="flex justify-center ">
            {isLoading ? (
              <Button disabled>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Please wait
              </Button>
            ) : (
              <Button
                className="bg-black"
                type="submit"
                disabled={isLoading || !messageContent}
              >
                Send It
              </Button>
            )}
          </div>
        </form>
      </Form>

      <div className="space-y-4 my-5">
        <div className="space-y-2">
          <p>
            Click on any message below to select it, use &ldquo;Suggest
            Messages&rdquo; for conversation starters, or write your message and
            click &ldquo;✨ Refine&rdquo; to improve it with AI.
          </p>
        </div>
        <Card>
          <CardHeader>
            <h3 className="text-xl font-bold justify-center flex">Messages</h3>
          </CardHeader>
          <CardContent className="flex flex-col space-y-4">
            {error ? (
              <p className="text-red-500">{error.message}</p>
            ) : (
              parseStringMessages(completion).map((message, index) => (
                <Button
                  key={index}
                  variant="outline"
                  className="mb-2 whitespace-normal break-words text-left"
                  onClick={() => handleMessageClick(message)}
                >
                  {message}
                </Button>
              ))
            )}
          </CardContent>
        </Card>
      </div>
      <div className="flex justify-center">
        <Button
          onClick={fetchSuggestedMessages}
          className="my-4 bg-black"
          disabled={isSuggestLoading}
        >
          {isSuggestLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Generating...
            </>
          ) : (
            "Suggest Messages"
          )}
        </Button>
      </div>
      <Separator className="my-6" />
      <div className="text-center flex justify-evenly">
        <div>
          <div className="mb-4 mt-5">Get Your Message Board</div>
          <Link href={"/sign-up"}>
            <Button className="bg-black">Create Your Account</Button>
          </Link>
        </div>
        <div>
          <div className="mb-4 mt-5">Give us feedback anonymously</div>
          <Link href={"/u/Truvoice"}>
            <Button className="bg-black">Give Feedback</Button>
          </Link>
        </div>
      </div>
    </div>
  );
}
