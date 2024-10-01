import { signInAction } from "@/app/actions";
import { SubmitButton } from "@/components/submit-button";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { AppLogoImageMedium } from "@/lib/theme-service";
import Link from "next/link";

export default async function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="grid gap-0 grid-cols-1 place-items-center min-h-screen justify-start">
      <form>
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle className="text-2xl">
              <div className="mb-4 mx-auto grid">
                <AppLogoImageMedium className="place-self-center" />
              </div>
            </CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4">
            <div className="grid gap-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" placeholder="m@example.com" required />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" required />
            </div>
          </CardContent>
          <CardFooter className="grid grid-cols-1 gap-5">
            <div>
              <SubmitButton className="w-full" pendingText="Signing In..." formAction={signInAction}>Sign In</SubmitButton>
            </div>

            <p className="text-sm text-muted-foreground">
              Don't have an account?{" "}
              <Link className="text-foreground font-medium underline" href="/sign-up">
                Sign Up
              </Link>
            </p>
          </CardFooter>
        </Card>
      </form>
    </div>
  );

}
