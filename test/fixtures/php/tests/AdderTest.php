<?php

namespace Fixture\Tests;

use Fixture\Adder;
use PHPUnit\Framework\TestCase;

class AdderTest extends TestCase
{
    public function testAdd(): void
    {
        $this->assertSame(5, Adder::add(2, 3));
    }
}
