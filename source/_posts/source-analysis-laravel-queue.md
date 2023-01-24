---
title: laravel源码分析-队列Queue
date: 2022-01-07 15:28:21
cover: 'https://cdn.immaxfang.com/images/post/2022/pg-source-analysis-laravel-queue.png'
categories: php
tags: [php,laravel,源码分析]
---

> laravel 源码分析具体注释见 [https://github.com/FX-Max/source-analysis-laravel](https://github.com/FX-Max/source-analysis-laravel)

# 前言

队列 (Queue) 是 laravel 中比较常用的一个功能，队列的目的是将耗时的任务延时处理，比如发送邮件，从而大幅度缩短 Web 请求和响应的时间。本文我们就来分析下队列创建和执行的源码。

> 本文笔者基于 laravel 5.8.* 版本

# 队列任务的创建

先通过命令创建一个 Job 类，成功之后会创建如下文件 laravel-src/laravel/app/Jobs/DemoJob.php。

```bash
> php artisan make:job DemoJob

> Job created successfully.
```

下面我们来分析一下 Job 类的具体生成过程。

执行 `php artisan make:job DemoJob` 后，会触发调用如下方法。

laravel-src/laravel/vendor/laravel/framework/src/Illuminate/Foundation/Providers/ArtisanServiceProvider.php

```php
/**
 * Register the command.
 * [A] make:job 时触发的方法
 * @return void
 */
protected function registerJobMakeCommand()
{
    $this->app->singleton('command.job.make', function ($app) {
        return new JobMakeCommand($app['files']);
    });
}
```

接着我们来看下 JobMakeCommand 这个类，这个类里面没有过多的处理逻辑，处理方法在其父类中。

```php
class JobMakeCommand extends GeneratorCommand
```

我们直接看父类中的处理方法，GeneratorCommand->handle()，以下是该方法中的主要方法。

```php
public function handle()
{
    // 获取类名
    $name = $this->qualifyClass($this->getNameInput());
    // 获取文件路径
    $path = $this->getPath($name);
    // 创建目录和文件
    $this->makeDirectory($path);
    // buildClass() 通过模板获取新类文件的内容
    $this->files->put($path, $this->buildClass($name));
    // $this->type 在子类中定义好了，例如 JobMakeCommand 中 type = 'Job'
    $this->info($this->type.' created successfully.');
}
```

方法就是通过目录和文件，创建对应的类文件，至于新文件的内容，都是基于已经设置好的模板来创建的，具体的内容在 buildClass($name) 方法中。

```php
protected function buildClass($name)
{
    // 得到类文件模板，getStub() 在子类中有实现，具体看 JobMakeCommand 
    $stub = $this->files->get($this->getStub());
    // 用实际的name来替换模板中的内容，都是关键词替换
    return $this->replaceNamespace($stub, $name)->replaceClass($stub, $name);
}
```

获取模板文件

```php
protected function getStub()
{
    return $this->option('sync')
                    ? __DIR__.'/stubs/job.stub'
                    : __DIR__.'/stubs/job-queued.stub';
}
```

job.stub

```php
<?php
/**
* job 类的生成模板
*/
namespace DummyNamespace;

use Illuminate\Bus\Queueable;
use Illuminate\Foundation\Bus\Dispatchable;

class DummyClass
{
    use Dispatchable, Queueable;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        //
    }
}
```

job-queued.stub

```php
<?php
/**
* job 类的生成模板
*/
namespace DummyNamespace;

use Illuminate\Bus\Queueable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;

class DummyClass implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        //
    }
}
```

下面看一下前面我们创建的一个Job类，DemoJob.php，就是来源于模板 job-queued.stub。

```php
<?php
/**
* job 类的生成模板
*/
namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;

class DemoJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        //
    }
}
```

至此，我们已经大致明白了队列任务类是如何创建的了。下面我们来分析下其是如何生效运行的。

# 队列任务的分发

任务类创建后，我们就可以在需要的地方进行任务的分发，常见的方法如下：

```
DemoJob::dispatch(); // 任务分发
DemoJob::dispatchNow(); // 同步调度，队列任务不会排队，并立即在当前进程中进行
```

下面先以 dispatch() 为例分析下分发过程。

```
trait Dispatchable
{
    public static function dispatch()
    {
        return new PendingDispatch(new static(...func_get_args()));
    }
}
```

```
class PendingDispatch
{
    protected $job;

    public function __construct($job)
    {   echo '[Max] ' . 'PendingDispatch ' . '__construct' . PHP_EOL;
        $this->job = $job;
    }

    public function __destruct()
    {   echo '[Max] ' . 'PendingDispatch ' . '__destruct' . PHP_EOL;
        app(Dispatcher::class)->dispatch($this->job);
    }
}
```

重点是 app(Dispatcher::class)->dispatch($this->job) 这部分。

我们先来分析下前部分 app(Dispatcher::class)，它是在 laravel 框架中自带的 BusServiceProvider 中向 $app 中注入的。

```
class BusServiceProvider extends ServiceProvider implements DeferrableProvider
{
    public function register()
    {
        $this->app->singleton(Dispatcher::class, function ($app) {
            return new Dispatcher($app, function ($connection = null) use ($app) {
                return $app[QueueFactoryContract::class]->connection($connection);
            });
        });
    }
}
```

看一下 Dispatcher 的构造方法，至此，我们已经知道前半部分 app(Dispatcher::class) 是如何来的了。

```
class Dispatcher implements QueueingDispatcher
{
    protected $container;
    protected $pipeline;
    protected $queueResolver;

    public function __construct(Container $container, Closure $queueResolver = null)
    {
        $this->container = $container;
        /**
         * Illuminate/Bus/BusServiceProvider.php->register()中
         * $queueResolver 传入的是一个闭包
         * function ($connection = null) use ($app) {
         *   return $app[QueueFactoryContract::class]->connection($connection);
         * }
         */
        $this->queueResolver = $queueResolver;
        $this->pipeline = new Pipeline($container);
    }

    public function dispatch($command)
    {
        if ($this->queueResolver && $this->commandShouldBeQueued($command)) {
        		// 将 $command 存入队列
            return $this->dispatchToQueue($command);
        }
        return $this->dispatchNow($command);
    }
}
```

BusServiceProvider 中注册了 Dispatcher::class ，然后 app(Dispatcher::class)->dispatch($this->job) 调用的即是 Dispatcher->dispatch()。

```
public function dispatchToQueue($command)
{
    // 获取任务所属的 connection
    $connection = $command->connection ?? null;
    /*
     * 获取队列实例，根据config/queue.php中的配置
     * 此处我们配置 QUEUE_CONNECTION=redis 为例，则获取的是RedisQueue
     * 至于如何通过 QUEUE_CONNECTION 的配置获取 queue ，此处先跳过，本文后面会具体分析。
     */
    $queue = call_user_func($this->queueResolver, $connection);

    if (! $queue instanceof Queue) {
        throw new RuntimeException('Queue resolver did not return a Queue implementation.');
    }
    // 我们创建的DemoJob无queue方法，则不会调用
    if (method_exists($command, 'queue')) {
        return $command->queue($queue, $command);
    }
    // 将 job 放入队列
    return $this->pushCommandToQueue($queue, $command);
}

protected function pushCommandToQueue($queue, $command)
{
    // 在指定了 queue 或者 delay 时会调用不同的方法，基本大同小异
    if (isset($command->queue, $command->delay)) {
        return $queue->laterOn($command->queue, $command->delay, $command);
    }

    if (isset($command->queue)) {
        return $queue->pushOn($command->queue, $command);
    }

    if (isset($command->delay)) {
        return $queue->later($command->delay, $command);
    }
    // 此处我们先看最简单的无参数时的情况，调用push()
    return $queue->push($command);
}
```

> 笔者的配置是 QUEUE_CONNECTION=redis ，估以此来分析，其他类型的原理基本类似。

配置的是 redis 时， $queue 是 RedisQueue 实例，下面我们看下 RedisQueue->push() 的内容。

Illuminate/Queue/RedisQueue.php

```
public function push($job, $data = '', $queue = null)
{
    /**
     * 获取队列名称
     * var_dump($this->getQueue($queue));
     * 创建统一的 payload，转成 json
     * var_dump($this->createPayload($job, $this->getQueue($queue), $data));
     */
    // 将任务和数据存入队列
    return $this->pushRaw($this->createPayload($job, $this->getQueue($queue), $data), $queue);
}

public function pushRaw($payload, $queue = null, array $options = [])
{
    // 写入redis中
    $this->getConnection()->eval(
        LuaScripts::push(), 2, $this->getQueue($queue),
        $this->getQueue($queue).':notify', $payload
    );
    // 返回id
    return json_decode($payload, true)['id'] ?? null;
}
```

至此，我们已经分析完了任务是如何被加入到队列中的。
