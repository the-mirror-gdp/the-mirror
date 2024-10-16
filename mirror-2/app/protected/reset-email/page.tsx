import { resetEmailAction } from "@/actions/auth";
import { FormMessage, Message } from "@/components/form-message";
import { SubmitButton } from "@/components/submit-button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default async function ResetEmail({
  searchParams,
}: {
  searchParams: Message;
}) {
  return (
    <form className="flex flex-col w-full max-w-md p-4 gap-2 [&>input]:mb-4">
      <h1 className="text-2xl font-medium">Reset email</h1>
      <p className="text-sm text-foreground/60">
        Please enter your new email and verify your password below.
      </p>
      <Label htmlFor="email" className="mt-3">
        New email
      </Label>
      <Input type="email" name="email" placeholder="Enter New Email" required />

      <Label htmlFor="password">Password</Label>
      <Input
        type="password"
        name="password"
        placeholder="Enter password"
        required
      />
      <SubmitButton formAction={resetEmailAction}>Reset email</SubmitButton>
      <FormMessage message={searchParams} />
    </form>
  );
}
