package com.zhaoxiangyang.eap.common.web;

import com.zhaoxiangyang.eap.common.api.ApiResponse;
import com.zhaoxiangyang.eap.common.context.RequestContext;
import com.zhaoxiangyang.eap.common.error.BusinessException;
import com.zhaoxiangyang.eap.common.error.ErrorCode;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import org.springframework.http.converter.HttpMessageNotReadableException;

/**
 * Unified exception mapping for servlet services.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusinessException(
            BusinessException exception
    ) {
        ErrorCode errorCode = exception.errorCode();

        return ResponseEntity
                .status(errorCode.httpStatus())
                .body(ApiResponse.failure(errorCode, exception.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodArgumentNotValid(
            MethodArgumentNotValidException exception
    ) {
        String message = exception.getBindingResult()
                .getFieldErrors()
                .stream()
                .findFirst()
                .map(error -> error.getField() + " " + error.getDefaultMessage())
                .orElse(ErrorCode.PARAM_INVALID.message());

        return badRequest(message);
    }

    @ExceptionHandler({
            ConstraintViolationException.class,
            HttpMessageNotReadableException.class,
            MissingRequestHeaderException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleInvalidRequest(Exception exception) {
        return badRequest(ErrorCode.PARAM_INVALID.message());
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodNotSupported(
            HttpRequestMethodNotSupportedException exception
    ) {
        ErrorCode errorCode = ErrorCode.REQUEST_METHOD_NOT_SUPPORTED;
        return ResponseEntity
                .status(errorCode.httpStatus())
                .body(ApiResponse.failure(errorCode));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNoResource(
            NoResourceFoundException exception
    ) {
        ErrorCode errorCode = ErrorCode.RESOURCE_NOT_FOUND;
        return ResponseEntity
                .status(errorCode.httpStatus())
                .body(ApiResponse.failure(errorCode));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpectedException(
            Exception exception
    ) {
        LOGGER.error(
                "Unhandled exception, requestId={}",
                RequestContext.currentRequestId(),
                exception
        );

        ErrorCode errorCode = ErrorCode.SYSTEM_ERROR;
        return ResponseEntity
                .status(errorCode.httpStatus())
                .body(ApiResponse.failure(errorCode));
    }

    private ResponseEntity<ApiResponse<Void>> badRequest(String message) {
        ErrorCode errorCode = ErrorCode.PARAM_INVALID;
        return ResponseEntity
                .status(errorCode.httpStatus())
                .body(ApiResponse.failure(errorCode, message));
    }
}
