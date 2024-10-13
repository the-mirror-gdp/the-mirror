'use client'
import { loginAction } from '@/actions/auth'
import { FormMessage, Message } from '@/components/form-message'
import { SubmitButton } from '@/components/submit-button'
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  CardFooter
} from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useRedirectToHomeIfSignedIn } from '@/hooks/auth'
import { AppLogoImageMedium } from '@/lib/theme-service'
import Link from 'next/link'
import { useRef } from 'react'

const isDevelopment = process.env.NODE_ENV === 'development'

export default function Login({ searchParams }: { searchParams: Message }) {
  useRedirectToHomeIfSignedIn()

  // References for email and password fields
  const emailRef = useRef<HTMLInputElement>(null)
  const passwordRef = useRef<HTMLInputElement>(null)

  // Function to simulate login with specific user
  const handleDevLoginWithUser = (userEmail: string) => {
    if (emailRef.current && passwordRef.current) {
      emailRef.current.value = userEmail
      passwordRef.current.value = 'password' // Default password for all dev users
    }

    // Simulate form submission by calling formAction
    // Since the SubmitButton uses formAction, this will trigger loginAction
    ;(document.getElementById('login-form') as HTMLFormElement)?.requestSubmit()
  }

  return (
    <form id="login-form" action={loginAction}>
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle className="text-2xl">
            <div className="mb-4 mx-auto grid">
              <AppLogoImageMedium className="place-self-center" />
            </div>
            Login
          </CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4">
          <div className="grid gap-2">
            <Label htmlFor="email">Email</Label>
            <Input
              ref={emailRef}
              id="email"
              type="email"
              name="email"
              placeholder="m@example.com"
              required
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="password">Password</Label>
            <Input
              ref={passwordRef}
              id="password"
              type="password"
              name="password"
              required
            />
          </div>
        </CardContent>
        <CardFooter className="grid grid-cols-1 gap-5">
          <SubmitButton
            className="w-full"
            pendingText="Signing In..."
            formAction={loginAction}
          >
            Login
          </SubmitButton>
          <FormMessage message={searchParams} />
          <p className="text-sm text-muted-foreground">
            Don't have an account?{' '}
            <Link
              className="text-foreground font-medium underline"
              href="/create-account"
            >
              Create Account
            </Link>
          </p>

          {/* Development-only login buttons */}
          {isDevelopment && (
            <div className="grid gap-2 mt-4">
              <button
                type="button"
                className="bg-gray-900 p-2 rounded-md"
                onClick={() => handleDevLoginWithUser('user1@example.com')}
              >
                Dev Login with User 1
              </button>
              <button
                type="button"
                className="bg-gray-900 p-2 rounded-md"
                onClick={() => handleDevLoginWithUser('user2@example.com')}
              >
                Dev Login with User 2
              </button>
              <button
                type="button"
                className="bg-gray-900 p-2 rounded-md"
                onClick={() => handleDevLoginWithUser('user3@example.com')}
              >
                Dev Login with User 3
              </button>
            </div>
          )}
        </CardFooter>
      </Card>
    </form>
  )
}
