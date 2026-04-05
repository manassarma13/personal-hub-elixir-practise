defmodule PersonalHubWeb.TimeHelpers do
  @moduledoc """
  Helper functions for formatting timestamps in templates.
  """

  @doc """
  Formats an ISO 8601 timestamp string into a human-readable relative time.
  Returns "just now", "5m ago", "2h ago", "3d ago", or a formatted date.
  """
  def relative_time(nil), do: ""
  def relative_time(""), do: ""

  def relative_time(iso_string) when is_binary(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _offset} ->
        now = DateTime.utc_now()
        diff = DateTime.diff(now, dt, :second)
        format_diff(diff)

      _ ->
        iso_string
    end
  end

  defp format_diff(diff) when diff < 60, do: "just now"
  defp format_diff(diff) when diff < 3600, do: "#{div(diff, 60)}m ago"
  defp format_diff(diff) when diff < 86400, do: "#{div(diff, 3600)}h ago"
  defp format_diff(diff) when diff < 604_800, do: "#{div(diff, 86400)}d ago"
  defp format_diff(diff) when diff < 2_592_000, do: "#{div(diff, 604_800)}w ago"
  defp format_diff(_diff), do: "over a month ago"

  @doc """
  Formats an ISO 8601 timestamp to a short date string like "Apr 6, 2026".
  """
  def format_date(nil), do: ""
  def format_date(""), do: ""

  def format_date(iso_string) when is_binary(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _offset} ->
        month = month_abbr(dt.month)
        "#{month} #{dt.day}, #{dt.year}"

      _ ->
        iso_string
    end
  end

  @doc """
  Formats an ISO 8601 timestamp to "Apr 6, 2026 at 3:45 PM".
  """
  def format_datetime(nil), do: ""
  def format_datetime(""), do: ""

  def format_datetime(iso_string) when is_binary(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _offset} ->
        month = month_abbr(dt.month)
        {hour_12, ampm} = to_12hour(dt.hour)
        minute = String.pad_leading(Integer.to_string(dt.minute), 2, "0")
        "#{month} #{dt.day}, #{dt.year} at #{hour_12}:#{minute} #{ampm}"

      _ ->
        iso_string
    end
  end

  @doc """
  Returns just the date portion of an ISO string as YYYY-MM-DD.
  """
  def to_date_key(nil), do: nil
  def to_date_key(""), do: nil

  def to_date_key(iso_string) when is_binary(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _offset} ->
        Date.to_iso8601(DateTime.to_date(dt))

      _ ->
        nil
    end
  end

  defp month_abbr(1), do: "Jan"
  defp month_abbr(2), do: "Feb"
  defp month_abbr(3), do: "Mar"
  defp month_abbr(4), do: "Apr"
  defp month_abbr(5), do: "May"
  defp month_abbr(6), do: "Jun"
  defp month_abbr(7), do: "Jul"
  defp month_abbr(8), do: "Aug"
  defp month_abbr(9), do: "Sep"
  defp month_abbr(10), do: "Oct"
  defp month_abbr(11), do: "Nov"
  defp month_abbr(12), do: "Dec"

  defp to_12hour(0), do: {12, "AM"}
  defp to_12hour(hour) when hour < 12, do: {hour, "AM"}
  defp to_12hour(12), do: {12, "PM"}
  defp to_12hour(hour), do: {hour - 12, "PM"}
end
