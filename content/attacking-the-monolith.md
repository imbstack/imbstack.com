+++
title = "Attacking the Monolith"
date = 2015-10-03
+++

##### Following is adapted from a talk I gave at [CWRU Link State 2015](http://acm.cwru.edu/acm/conference/2015).

I want to start by making a simple, uncontroversial statement. One that we should all agree on, but one that is often forgotten or ignored by professional software engineers:

> Software has a purpose.

This is simple almost to the point of tautology. However, I and most of us who've done this sort of work have lost sight of that many times before. Let me explain what I mean by this.

I've been writing software for a while now. The last two of which were out in San Francisco for that big local reviews website we all know and love. The majority of our code was in a single, large, monolithic project. From when I started there, the size of our engineering team doubled and then doubled again, finishing at over 400 engineers by the time I left. Most of my time there was spent on the team responsible for building and running the tools developers used to develop. We also helped set the policies we had for how to deploy new code and even how to write it in the first place. I was involved in quite a few technical and policy decisions over the course of my time there and was a part of successes and failures. Many of both of the outcomes came as a result of either remembering or forgetting that software has a purpose.

From the moment you start reading about or being taught about how to write software, you learn that modularity is important. Separation of concerns and interfaces, objects and APIs. A natural outgrowth of this is a Service Oriented Architecture. I've worked on and built both monolithic and SOA projects. I've worked on the underlying infrastructure of both as well. I've found a tendency over time for orthodoxies to build up around both camps. Software engineers, I have found, have a penchant for orthodoxy.

I was lucky enough while I was in school to have worked for a networking researcher who spoke of engineering trade-offs religiously and at every opportunity. It's easy as an undergraduate computer major to fall into the trap of thinking there is one correct solution to every problem. We are all told of time and space trade-offs, but in the vacuum of a test, there is only one correct answer.

A SOA has many enticing positives, but also comes with drawbacks. It also requires you to enter a different headspace. While you win strictly enforced boundaries between different elements of your system, you pay for it by needing to find a way to enforce strict interfaces. While you win fine grained scalability and flexibility, you must now build and maintain a robust service discovery layer, not to mention the actual transport in the first place. While you win the ability to use the right tool for the job, you pay for it by expanding the knowledge surface areas needed by your engineers; polyglot engineering requires frequent context switching by human beings, which will prove costly

On the topic of testing (a topic very near and dear to my heart), I have found that engineers will want to build themselves false safety nets and reach across nicely defined boundaries in an effort to prevent any regressions from occurring. The warm fuzzy blanket of a proliferation of end-to-end, integration, and acceptance tests results in a combinatoric explosion in the number of tests and requires you to run disparate codebase's tests any time you deploy any service. Not even unit tests can save you: make them too brittle and they will be nearly tautological, required line-by-line changes to tests every time you change the code.

My coworkers and I once came across a est that was designed to prevent PII from leaking into our logs. When an engineer tasked with upgrading an underlying library caused the test to fail, they simply inverted the condition and made the test pass. The line above the regex was a comment stating, <span class="code">#Don't allow PII in our logs!</span> The mistake was only found weeks after the code had been running in production. Remember: tests only test what you tell them to.

It is tempting to blame the engineer who made that change; to laugh at them or scold them. However, if we're being completely honest with ourselves, we know that this sort of thing is a common mistake and that we all do it all of the time. The first thing a software engineer must recognize is that human beings suck at writing code. I is an inherently difficult process for our minds to create logically correct statements. There are about as many techniques that claim to alleviate these issues as there are techniques that generally fail to do so.

> Nothing can save you. Accept failure.

> But there is hope.

Now, given that you will fail, what can you do about it? The most important thing you can do is _reduce your time to recover from failure_. This has two parts to it: First is being able to know when you are failing. Second is to have a way to undo or fix your bad things as soon as you can. Most major failure situations occur when we (human beings) change code.

These two goals go hand-in-hand. Monitoring checks on your production code (not just "does it return a 200") are very conceptually similar to the tests you would normally be writing, but they run against something real. There will always be differences between your development or staging environment and your production one. Obviously not all software is a website, but a heck of a lot of it does communicate across a network with a server in some way. Even if your application is completely standalone, it can still phone-home (for better or worse) to report failures and metrics.

These are some of the most powerful things you can do as an engineer. Detecting failures once in happens is equally important to preventing failure in the first place. At that big reviews site, the CEO and VP of engineering were brothers. A fairly common occurrence was getting bug reports from their mother. These obviously became high priority bugs almost instantaneously. Don't let one of your primary lines of defence be your CEO's parents. Everyone will be less happy that way (most of all their parents).

At that company, our first line of defense was testing. In our attempt to alleviate failure, we ended up with almost 60,000 tests that would be run whenever a developer made changes and also before a deploy.

We invested a heck of a lot of computing power and developer effort in keeping these tests fast and un-flaky. Through a judicious application of well over 100 of Amazon's largest instances and a team of 4-8 engineers (who are more expensive than those machines) we cold run all of those tests in about 20 minutes. We applied all sorts of other efforts to reducing the flakiness of the tests. When there are false positives for test failure, you will miss the true positives more frequently.

> Writing good tests is really, really, really difficult.

Even with all of those tests and a short stop in a staging environment before a deploy, we would still see multiple failures in production per week. We strove to deploy 3 times a day, every day. Each deploy would contain something like 15 branches. A failure when we got to prod would be extremely costly in terms of developer time. Deciding which failures were worth abort a deploy for was a stressful and difficult decision. Oftentimes a failure could've been fixed in a few minutes by rolling forward, but taking all of that time to run the tests, not to mention fixing them in the first place, generally meant that aborting was the less costly choice.

This brings us to an important question. A website or any piece of software is really made up of different functions. Not in the programming "function" sense, but in the user facing sense. As an example, on that big reviews site, you could:

- read reviews
- write reviews
- upload pictures
- view pictures
- signup
- login
- chat with other users (how many of you knew we had that?)
- search for businesses
- search for users
- claim a business as your own
- track how users were interacting with your business
- buy ads
- view ads (most important!)

And that is just a partial list. So, the question is

> How important is each part of the site in relation to each other?

As a software engineer, it is embarrassing to have something you are working on be wrong. Something about the programming mindset forces us to hone in on minutiae and obsess over _getting it right_. Our deploy system had tags you could apply to the equivalent of a pull request. A common and well understood tag was "Urgent." This meant that the change should be deployed ASAP, to the point of jumping in line before other requests or perhaps even being deployed on its own. The intended purpose for the tag was identifying requests that could stop us from actively losing money or stop something really bad from happening. If _essential_ functionality was broken, this would be the appropriate tag to use. However, more often than note, I saw it being used for requests the really should have been tagged, "Embarrassing." A button being the wrong color, mis-formatted text, or a stray comment that was ultimately harmless. Did users really care about these issues? Probably not. Did these issues really require and urgent deploy? Probably not.

It's really easy to get sucked into your little bit of the puzzle and think that it has to be perfect. I've been guilty of this more than once. I think it is only natural for people who take pride in ownership to go beyond reason once in a while. We all need to remember, at the end of the day

> Software has a purpose

Given that software has a purpose, what sort of decisions can we make? One of the most important things you will all decide in the next couple years (or next couple months) is where you will be applying your trade after you graduate from here. A common thought among graduating CS kids when I was here is that all we were looking for was a "fun problem." Combine a fun problem with great compensation and we were sold. I want to argue that these should take a back seat to something more important. Whether you end up continuing into grad school, working for a company, working for the government, or something else entirely, the software you create and maintain has a purpose. Keeping that in mind and aligning that with your personal moral compass will do a lot for the world and keep you content as you work hard to keep the software working. This is not to say that we should ignore fun problems and compensation (particularly if you have student debt to pay back), but we should strive to find a way to help people in the process.

I haven't found how to do this best yet, but I promise I'll keep looking.
