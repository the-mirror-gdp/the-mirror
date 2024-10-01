import { createAccountAction, loginAction } from "@/actions/actions";
import { FormMessage, Message } from "@/components/form-message";
import { SubmitButton } from "@/components/submit-button";
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { AppLogoImageMedium } from "@/lib/theme-service";
import Link from "next/link";

export default function CreateAccount({ searchParams }: { searchParams: Message }) {
  return (
    <form>
      <Card className="w-full max-w-sm">
        <CardHeader className="px-6 pt-6 pb-3">
          <CardTitle className="text-2xl">
            <div className="mb-4 mx-auto grid">
              <AppLogoImageMedium className="place-self-center" />
            </div>
            Create Account
          </CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4">
          <div className="grid gap-2">
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" name="email" placeholder="m@example.com" required />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="password">Password</Label>
            <Input id="password" type="password" name="password" required />
          </div>
        </CardContent>
        <CardFooter className="grid grid-cols-1 gap-3">
          <SubmitButton className="w-full" pendingText="Creating Account..." formAction={createAccountAction}>Create Account</SubmitButton>
          <FormMessage message={searchParams} />
          <p className="text-sm text-muted-foreground">
            Already have an account?{" "}
            <Link className="text-foreground font-medium underline" href="/login">
              Login
            </Link>
          </p>
        </CardFooter>
      </Card>
    </form>
  );
}
