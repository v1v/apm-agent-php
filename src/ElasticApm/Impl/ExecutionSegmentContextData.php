<?php

declare(strict_types=1);

namespace Elastic\Apm\Impl;

use Elastic\Apm\Impl\BackendComm\SerializationUtil;
use Elastic\Apm\Impl\Log\LoggableInterface;
use Elastic\Apm\Impl\Log\LoggableTrait;
use JsonSerializable;

/**
 * Code in this file is part of implementation internals and thus it is not covered by the backward compatibility.
 *
 * @internal
 */
class ExecutionSegmentContextData implements JsonSerializable, LoggableInterface
{
    use LoggableTrait;

    /** @var array<string, string|bool|int|float|null> */
    public $labels = [];

    /**
     * @return bool
     */
    public function isEmpty(): bool
    {
        return empty($this->labels);
    }

    public function jsonSerialize()
    {
        $result = [];

        // APM Server Intake API expects 'tags' key for labels
        // https://github.com/elastic/apm-server/blob/7.0/docs/spec/context.json#L46
        // https://github.com/elastic/apm-server/blob/7.0/docs/spec/spans/span.json#L88
        SerializationUtil::addNameValueIfNotEmpty('tags', $this->labels, /* ref */ $result);

        return $result;
    }
}
